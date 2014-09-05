class Event < ActiveRecord::Base
  has_many :hangouts
  serialize :exclusions

  serialize :exclusions

  extend FriendlyId
  friendly_id :name, use: :slugged

  include IceCube
  validates :name, :time_zone, :repeats, :category, :start_datetime, :duration, presence: true
  validates :url, uri: true, :allow_blank => true
  validates :repeats_every_n_weeks, :presence => true, :if => lambda { |e| e.repeats == 'weekly' }
  validate :must_have_at_least_one_repeats_weekly_each_days_of_the_week, :if => lambda { |e| e.repeats == 'weekly' }
  attr_accessor :next_occurrence_time_attr
  attr_accessor :repeat_ends_string

  COLLECTION_TIME_FUTURE = 10.days
  COLLECTION_TIME_PAST = 15.minutes

  REPEATS_OPTIONS = %w[never weekly]
  REPEAT_ENDS_OPTIONS = %w[never on]
  DAYS_OF_THE_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday]

  def repeat_ends_as_string
    repeat_ends ? "on" : "never"
  end

  def set_repeat_ends_string
    @repeat_ends_string = repeat_ends ? "on" : "never"
  end

  def self.hookups
    Event.where(category: "PairProgramming")
  end

  def self.pending_hookups
    pending = []
    hookups.each do |h|
      started = h.last_hangout && h.last_hangout.started?
      expired_without_starting = !h.last_hangout && Time.now.utc > h.instance_end_time
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
    repeat_ends && repeat_ends_on.present? ? repeat_ends_on.to_time : nil
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
    if repeating_and_ends? && options[:end_time].present?
      final_datetime = [options[:end_time], repeat_ends_on.to_datetime].min
    elsif repeating_and_ends?
      final_datetime = repeat_ends_on.to_datetime
    else
      final_datetime = options[:end_time]
    end
    final_datetime ? final_datetime.to_datetime.utc : COLLECTION_TIME_FUTURE.from_now
  end

  def start_datetime_for_collection(options = {})
    first_datetime = options.fetch(:start_time, COLLECTION_TIME_PAST.ago)
    first_datetime = [start_datetime, first_datetime.to_datetime].max
    first_datetime.to_datetime.utc
  end

  def next_occurrence_time_method(start = Time.now)
    next_occurrence = next_event_occurrence_with_time(start)
    next_occurrence.present? ? next_occurrence[:time] : nil
  end

  def self.next_scrum_occurrence(begin_time = COLLECTION_TIME_PAST.ago)
    _events = []
    Event.where(['category = ?', 'Scrum']).each do |event|
      _occurrence = event.next_event_occurrence_with_time(begin_time)
      _events << _occurrence if _occurrence.present?
    end
    return nil if _events.empty?
    _events = _events.sort_by { |e| e[:time] }
    _events[0][:event].next_occurrence_time_attr = _events[0][:time]
    return _events[0][:event]
  end

  #looks into the future for the next event occurrence, just in case some have been excluded
  def next_event_occurrence_with_time(start = Time.now)
    begin_datetime = start_datetime_for_collection(start_time: start)
    final_datetime = repeating_and_ends? ? repeat_ends_on : 10.years.from_now
    n_days = 8
    end_datetime = n_days.days.from_now
    _event = nil
    while _event.nil? and end_datetime < final_datetime
      _event = next_event_occurrence_with_time_inner(start, final_datetime)
      n_days *= 2
      end_datetime = n_days.days.from_now
    end
    _event
  end

  def next_event_occurrence_with_time_inner(start_time, end_time)
    _occurrences = occurrences_between(start_time, end_time)
    if _occurrences.present?
      { event: self, time: _occurrences.first.start_time }
    else
      nil
    end
  end

  def next_occurrences(options = {})
    begin_datetime = start_datetime_for_collection(options)
    final_datetime = final_datetime_for_collection(options)
    limit = options.fetch(:limit, 100)

    [].tap do |occurences|
      occurrences_between(begin_datetime, final_datetime).each do |time|
        occurences << { event: self, time: time }

        return occurences if occurences.count >= limit
      end
    end
  end

  def occurrences_between(start_time, end_time)
    schedule().occurrences_between(start_time.to_time, end_time.to_time)
  end

  def repeats_weekly_each_days_of_the_week=(repeats_weekly_each_days_of_the_week)
    self.repeats_weekly_each_days_of_the_week_mask = (repeats_weekly_each_days_of_the_week & DAYS_OF_THE_WEEK).map { |r| 2**DAYS_OF_THE_WEEK.index(r) }.inject(0, :+)
  end

  def repeats_weekly_each_days_of_the_week
    DAYS_OF_THE_WEEK.reject do |r|
      ((repeats_weekly_each_days_of_the_week_mask || 0) & 2**DAYS_OF_THE_WEEK.index(r)).zero?
    end
  end

  def remove_from_schedule(timedate)
    # best if schedule is serialized into the events record...  and an attribute.
    if timedate >= Time.now && timedate == next_occurrence_time_method
      _next_occurrences = next_occurrences(limit: 2)
      self.start_datetime = (_next_occurrences.size > 1) ? _next_occurrences[1][:time] : timedate + 1.day
    elsif timedate >= Time.now
      @exclusions ||= []
      @exclusions << timedate
    end
    save
  end

  def schedule()
    sched = series_end_time.nil? || !repeat_ends ? IceCube::Schedule.new(start_datetime) : IceCube::Schedule.new(start_datetime, :end_time => series_end_time)
    case repeats
      when 'never'
        sched.add_recurrence_time(start_datetime)
      when 'weekly'
        days = repeats_weekly_each_days_of_the_week.map { |d| d.to_sym }
        sched.add_recurrence_rule IceCube::Rule.weekly(repeats_every_n_weeks).day(*days)
    end
    @exclusions ||= []
    @exclusions.each do |ex|
      sched.add_exception_time(ex)
    end
    sched
  end

  def self.transform_params(params)
    event_params = params.require(:event).permit!
    if (params['start_date'].present? && params['start_time'].present?)
      event_params[:start_datetime] = "#{params['start_date']} #{params['start_time']} UTC"
    end
    event_params[:repeat_ends] = (event_params['repeat_ends_string'] == 'on')
    event_params[:repeat_ends_on]= "#{params[:repeat_ends_on]} UTC"
    event_params
  end

  def start_time_with_timezone
    DateTime.parse(start_time.strftime('%k:%M ')).in_time_zone(time_zone)
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

  def repeating_and_ends?
    repeats != 'never' && repeat_ends && !repeat_ends_on.blank?
  end

end
