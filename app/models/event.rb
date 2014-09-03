class Event < ActiveRecord::Base
  has_many :hangouts

  extend FriendlyId
  friendly_id :name, use: :slugged

  include IceCube
  validates :name, :category, :duration, :schedule_yaml, presence: true
  validates :url, uri: true, :allow_blank => true
  attr_accessor :next_occurrence_time_attr

  REPEATS_OPTIONS = %w[never weekly]
  REPEAT_ENDS_OPTIONS = %w[never on]
  DAYS_OF_THE_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday]

  def self.hookups
    Event.where(category: "PairProgramming")
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

  def live?
    last_hangout.present? && last_hangout.live?
  end

  def final_datetime_for_collection(final_datetime= 10.days.from_now)
    sched = Schedule.from_yaml(schedule_yaml)
    final_datetime = [final_datetime, sched.end_time].min if sched.end_time.present?
    final_datetime.to_datetime.utc
  end

  def start_datetime_for_collection(first_datetime= 15.minutes.ago)
    sched = Schedule.from_yaml(schedule_yaml)
    first_datetime = [sched.start_time, first_datetime.to_datetime].max if sched.start_time.present?
    first_datetime.to_datetime.utc
  end

  def self.next_event_occurrence(start_time= 15.minutes.ago, end_time = 10.days.from_now)
    if Event.exists?
      @events = []
      Event.where(['category = ?', 'Scrum']).each do |event|
        next_occurences = event.next_occurrences(start_time,
                                                 end_time,
                                                 1)
        @events << next_occurences.first unless next_occurences.empty?
      end

      return nil if @events.empty?

      @events = @events.sort_by { |e| e[:time] }
      @events[0][:event].next_occurrence_time_attr = @events[0][:time]
      return @events[0][:event]
    end
    nil
  end

  def next_occurrence_time_method(start_time= 15.minutes.ago, end_time = 10.days.from_now)
    next_occurrence_set = next_occurrences(start_time, end_time)
    !next_occurrence_set.empty? ? next_occurrence_set.first[:time].time : 0
  end

  def next_occurrences(start_time= 15.minutes.ago, end_time = 10.days.from_now, limit = 100)
    begin_datetime = start_datetime_for_collection(start_time)
    final_datetime = final_datetime_for_collection(end_time)

    [].tap do |occurences|
      occurrences_between(begin_datetime, final_datetime).each do |time|
        occurences << { event: self, time: time }

        return occurences if occurences.count >= limit
      end
    end
  end

  def occurrences_between(start_time, end_time)
    schedule.occurrences_between(start_time.to_time, end_time.to_time)
  end

  def repeats_weekly_each_days_of_the_week=(repeats_weekly_each_days_of_the_week)
    self.repeats_weekly_each_days_of_the_week_mask = (repeats_weekly_each_days_of_the_week & DAYS_OF_THE_WEEK).map { |r| 2**DAYS_OF_THE_WEEK.index(r) }.inject(0, :+)
  end

  def repeats_weekly_each_days_of_the_week
    DAYS_OF_THE_WEEK.reject do |r|
      ((repeats_weekly_each_days_of_the_week_mask || 0) & 2**DAYS_OF_THE_WEEK.index(r)).zero?
    end
  end

  def remove_from_schedule(date)
    # best if schedule is serialized into the events record... and an attribute.
    #schedule.exdate(date)
    schedule.from_yaml(schedule_yaml)
    schedule.extime(Time.local(date.year, date.month, date.day))
    schedule_yaml = schedule.to_yaml
  end

  def schedule(starts_at = nil, ends_at = nil)
    # starts_at ||= start_datetime
    # ends_at ||= end_time
    sched = Schedule.from_yaml(schedule_yaml)
    sched.start_time= [sched.start_time, starts_at.to_datetime].max if starts_at.present?
    sched.end_time= [sched.end_time, ends_at.to_datetime].min if ends_at.present?
    sched
    # schedule.start_time= starts_at
    # schedule.end_time= ends_at
  end

  def generate_schedule(params)
    temp_params = params.require(:event).permit!
    temp_params[:start_datetime] = "#{params['start_date']} #{params['start_time']} UTC"
    if params[:repeats] != 'never'
      if (params[:repeat_ends])
        schedule = Schedule.new(params[:start_datetime], :end_time => params[:repeat_ends_on])
      else
        schedule = Schedule.new(params[:start_datetime])
      end
      if (params[:repeats_weekly_each_days_of_the_week].present?)
        days = params[:repeats_weekly_each_days_of_the_week].map { |d| d.to_sym }
        schedule.add_recurrence_rule IceCube::Rule.weekly(params[:repeats_every_n_weeks]).day(*days)
      end
    else
      schedule = Schedule.new(params[:start_datetime])
    end
    schedule_yaml = schedule.to_yaml
  end

  def generate_schedule()
    if repeats != 'never'
      if (repeat_ends)
        schedule = Schedule.new(start_datetime, :end_time => repeat_ends_on)
      else
        schedule = Schedule.new(start_datetime)
      end
      if (repeats_weekly_each_days_of_the_week.present?)
        days = repeats_weekly_each_days_of_the_week.map { |d| d.to_sym }
        schedule.add_recurrence_rule IceCube::Rule.weekly(repeats_every_n_weeks).day(*days)
      end
    else
      schedule = Schedule.new(start_datetime)
    end
    schedule_yaml = schedule.to_yaml
  end

  def repeat_ends?
    sched = Schedule.from_yaml(schedule_yaml)
    sched.terminating?
  end

  def repeats?
    sched = Schedule.from_yaml(schedule_yaml)
    !sched.recurrence_rules.empty?
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


  def last_hangout
    hangouts.order(:created_at).last
  end

  private
end
