class Event < ActiveRecord::Base
  has_many :hangouts

  extend FriendlyId
  friendly_id :name, use: :slugged

  include IceCube
  validates :name, :time_zone, :repeats, :category, :start_datetime, :duration, presence: true
  validates :url, uri: true, :allow_blank => true
  validates :repeats_every_n_weeks, :presence => true, :if => lambda { |e| e.repeats == 'weekly' }
  validate :must_have_at_least_one_repeats_weekly_each_days_of_the_week, :if => lambda { |e| e.repeats == 'weekly' }
  attr_accessor :next_occurrence_time

  RepeatsOptions = %w[never weekly]
  RepeatEndsOptions = %w[never on]
  DaysOfTheWeek = %w[monday tuesday wednesday thursday friday saturday sunday]

  def self.hookups
    Event.where(category: "PairProgramming")
  end

  def self.scrum_templates
    Event.where(category: "Scrum")
  end

  def self.next_scrums(options = {})
    scrums_with_times = []
    scrum_templates.each do |scrum_template|
      scrums_with_times << scrum_template.next_occurrences(options)
    end
    scrums_with_times = scrums_with_times.flatten.sort_by { |s| s[:time] }
    scrum_instances = []
    scrums_with_times.each do |scrum_with_times|
      @event = Event.new
      tempEvent = scrum_with_times[:event]
      @event = Event.new(name: tempEvent.name,
                         duration: tempEvent.duration,
                         category: tempEvent.category,
                         id: tempEvent.id,
                         start_datetime: scrum_with_times[:time])
      scrum_instances << @event
    end
    scrum_instances
  end

  def self.pending_scrums(options = {})
    next_scrums(options).select{ |scrum|
      #expired_without_starting = Time.now.utc > scrum.start_datetime
      !(scrum.last_hangout && scrum.last_hangout.started?)
    }
  end

  def self.pending_hookups
    pending = []
    hookups.each do |h|
      started = h.last_hangout && h.last_hangout.started?
      expired_without_starting = !h.last_hangout && Time.now.utc > h.end_time
      pending << h if !started && !expired_without_starting
    end
    pending
  end

  def event_date
      start_datetime
  end

  def start_time
      start_datetime
  end

  def end_time
      (start_datetime + duration*60).utc
  end

  def end_date
    if (end_time < start_time)
      (event_date.to_datetime + 1.day).strftime('%Y-%m-%d')
    else
      event_date
    end
  end

  def last_hangout
    hangouts.last
  end

  def live?
    last_hangout.try!(:live?)
  end

  def self.next_event_occurrence
    if Event.exists?
      @events = []
      Event.where(['category = ?', 'Scrum']).each do |event|
        next_occurences = event.next_occurrences(start_time: 15.minutes.ago,
                                                 limit: 1)
        @events << next_occurences.first unless next_occurences.empty?
      end

      return nil if @events.empty?

      @events = @events.sort_by { |e| e[:time] }
      @events[0][:event].next_occurrence_time = @events[0][:time]
      return @events[0][:event]
    end
    nil
  end

  def next_occurrences(options = {})
    start_time_using_record = [30.minutes.ago, start_datetime].max
    start_time = (options[:start_time] or start_time_using_record)
    end_time_using_record = repeat_ends_on != "never" ? repeat_ends_on : 10.days.from_now
    end_time = (options[:end_time] or end_time_using_record)
    limit = (options[:limit] or 100)

    [].tap do |occurences|
      occurrences_between(start_time, end_time).each do |time|
        occurences << {event: self, time: time}

        return occurences if occurences.count >= limit
      end
    end
  end

  def occurrences_between(start_time, end_time)
    schedule.occurrences_between(start_time, end_time)
  end

  def repeats_weekly_each_days_of_the_week=(repeats_weekly_each_days_of_the_week)
    self.repeats_weekly_each_days_of_the_week_mask = (repeats_weekly_each_days_of_the_week & DaysOfTheWeek).map { |r| 2**DaysOfTheWeek.index(r) }.inject(0, :+)
  end

  def repeats_weekly_each_days_of_the_week
    DaysOfTheWeek.reject do |r|
      ((repeats_weekly_each_days_of_the_week_mask || 0) & 2**DaysOfTheWeek.index(r)).zero?
    end
  end

  def from
    ActiveSupport::TimeZone[time_zone].parse(event_date.to_datetime.strftime('%Y-%m-%d')).beginning_of_day + start_time.seconds_since_midnight
  end

  def to
    ActiveSupport::TimeZone[time_zone].parse(event_date.to_datetime.strftime('%Y-%m-%d')).beginning_of_day + end_time.seconds_since_midnight
  end

  def schedule(starts_at = nil, ends_at = nil)
    starts_at ||= from
    ends_at ||= to
    if duration > 0
      s = IceCube::Schedule.new(starts_at, :ends_time => ends_at, :duration => duration)
    else
      s = IceCube::Schedule.new(starts_at, :ends_time => ends_at)
    end
    case repeats
      when 'never'
        s.add_recurrence_time(starts_at)
      when 'weekly'
        days = repeats_weekly_each_days_of_the_week.map { |d| d.to_sym }
        s.add_recurrence_rule IceCube::Rule.weekly(repeats_every_n_weeks).day(*days)
    end
    s
  end

  def start_time_with_timezone
    DateTime.parse(start_time.strftime('%k:%M ')).in_time_zone(time_zone)
  end

  #deprecated methods
  def event_date= (d)
    raise "old schema error"
  end

  def start_time= (t)
    raise "old schema error"
  end

  def end_time= (t)
    raise "old schema error"
  end

  private
  def must_have_at_least_one_repeats_weekly_each_days_of_the_week
    if repeats_weekly_each_days_of_the_week.empty?
      errors.add(:base, 'You must have at least one repeats weekly each days of the week')
    end
  end

end
