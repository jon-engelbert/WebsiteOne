class Event < ActiveRecord::Base
  has_many :hangouts

  extend FriendlyId
  friendly_id :name, use: :slugged

  include IceCube
  validates :name, :time_zone, :repeats, :category, :start_datetime, :duration, presence: true
  validates :url, uri: true, :allow_blank => true
  validates :repeats_every_n_weeks, :presence => true, :if => lambda { |e| e.repeats == 'weekly' }
  validate :must_have_at_least_one_repeats_weekly_each_days_of_the_week, :if => lambda { |e| e.repeats == 'weekly' }
  attr_accessor :next_occurrence_time_attr
  attr_accessor :repeat_ends_string

  @@collection_time_future = 10.days
  @@collection_time_past = 15.minutes
  cattr_accessor :collection_time_future
  cattr_accessor :collection_time_past

  REPEATS_OPTIONS = %w[never weekly]
  REPEAT_ENDS_OPTIONS = %w[never on]
  DAYS_OF_THE_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday]

  def repeat_ends_as_string
    @repeat_ends ? "on" : "never"
  end

  def set_repeat_ends_string
    @repeat_ends_string = @repeat_ends ? "on" : "never"
  end

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

  def series_end_time
    repeat_ends ? repeat_ends_on : '2049-12-31 23:30:00 UTC'.to_datetime
  end

  def instance_end_time
    (start_datetime + duration*60).utc
  end

  def end_date
    if (series_end_time < start_time)
      (event_date.to_datetime + 1.day).strftime('%Y-%m-%d')
    else
      event_date
    end
  end

  def live?
    last_hangout.present? && last_hangout.live?
  end

  def final_datetime_for_collection(options = {})
    final_datetime = options.fetch(:end_time, @@collection_time_future.from_now)
    final_datetime = [final_datetime, repeat_ends_on.to_datetime].min if repeating_and_ends
    final_datetime.to_datetime.utc
  end

  def start_datetime_for_collection(options = {})
    first_datetime = options.fetch(:start_time, @@collection_time_past.ago)
    first_datetime = [start_datetime, first_datetime.to_datetime].max
    first_datetime.to_datetime.utc
  end

  def self.next_event_occurrence
    if Event.exists?
      @events = []
      Event.where(['category = ?', 'Scrum']).each do |event|
        next_occurences = event.next_occurrences(start_time: @@collection_time_past.ago,
                                                 end_time: @@collection_time_future.from_now,
                                                 limit: 1)
        @events << next_occurences.first unless next_occurences.empty?
      end

      return nil if @events.empty?

      @events = @events.sort_by { |e| e[:time] }
      @events[0][:event].next_occurrence_time_attr = @events[0][:time]
      return @events[0][:event]
    end
    nil
  end

  def next_occurrence_time_method(options = {})
    next_occurrence_set = next_occurrences(options)
    !next_occurrence_set.empty? ? next_occurrence_set.first[:time].time : 0
  end

  def next_occurrences(options = {})
    begin_datetime = start_datetime_for_collection(options)
    final_datetime = final_datetime_for_collection(options)
    limit = (options[:limit] or 100)

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
    # best if schedule is serialized into the events record...  and an attribute.
    schedule.from_yaml(schedule_yaml)
    schedule.extime(Time.local(date.year, date.month, date.day))
    Event.update_attribute(:schedule_yaml, schedule.to_yaml)
  end

  def schedule(starts_at = nil, ends_at = nil)
    if schedule_yaml.present?
      sched = Schedule.from_yaml(schedule_yaml)
      sched.start_time= [sched.start_time, starts_at.to_datetime].max if starts_at.present?
      if sched.end_time.nil? && ends_at.present?
        sched.end_time= ends_at.to_datetime
      elsif sched.end_time.present? && ends_at.present?
        sched.end_time= [sched.end_time, ends_at.to_datetime].min
      end
    else
      starts_at ||= start_datetime
      ends_at ||= series_end_time
      sched = IceCube::Schedule.new(starts_at, :end_time => ends_at)
    end
    sched
  end

  def self.generate_params_with_schedule(params)
    event_params = params.require(:event).permit!
    if (params['start_date'].present? && params['start_time'].present?)
      event_params[:start_datetime] = "#{params['start_date']} #{params['start_time']} UTC"
    end
    if event_params[:repeats] != 'never'
      if (event_params[:repeat_ends_string].present? && event_params[:repeat_ends_string] == 'on' && event_params[:start_datetime].present?)
        sched = Schedule.new(event_params[:start_datetime].to_datetime, :end_time => event_params[:repeat_ends_on])
      elsif (event_params[:start_datetime].present?)
        sched = Schedule.new(event_params[:start_datetime].to_datetime)
      else
        sched= Schedule.new()
      end
      if (event_params[:repeats_weekly_each_days_of_the_week].present?)
        event_params[:repeats_weekly_each_days_of_the_week] = event_params[:repeats_weekly_each_days_of_the_week].reject(&:blank?)
        repeat_day_symbols = event_params[:repeats_weekly_each_days_of_the_week].map { |d| d.to_sym }
        sched.add_recurrence_rule IceCube::Rule.weekly(event_params[:repeats_every_n_weeks]).repeat_day_symbols(*days)
      end
    else
      sched = Schedule.new(event_params[:start_datetime].to_datetime)
    end
    event_params['schedule_yaml'] = sched.to_yaml
    event_params
  end

  def generate_schedule
    if repeats != 'never'
      if (repeat_ends)
        sched = Schedule.new(start_datetime, :end_time => repeat_ends_on)
      else
        sched = Schedule.new(start_datetime)
      end
      if (repeats_weekly_each_days_of_the_week_mask.present?)
        repeat_day_strings = repeats_weekly_each_days_of_the_week.reject(&:blank?)
        repeat_day_symbols = repeat_day_strings.map { |d| d.to_sym }
        sched.add_recurrence_rule IceCube::Rule.weekly(repeats_every_n_weeks).day(*repeat_day_symbols)
      end
    else
      sched = Schedule.new(start_datetime)
    end
    self.schedule_yaml= sched.to_yaml
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
  def must_have_at_least_one_repeats_weekly_each_days_of_the_week
    if repeats_weekly_each_days_of_the_week.empty?
      errors.add(:base, 'You must have at least one repeats weekly each days of the week')
    end
  end

  def repeating_and_ends
    repeats != 'never' && repeat_ends && !repeat_ends_on.blank?
  end
end
