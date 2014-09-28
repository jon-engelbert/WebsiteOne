class Event < ActiveRecord::Base
  has_many :event_instances
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

  def set_repeat_ends_string
    @repeat_ends_string = repeat_ends ? "on" : "never"
  end

  def self.repeating_event_templates
    Event.where(:repeats != 'never')
  end

  def self.pending_event_instances(options = {})
    event_instances = []
    Event.all.each do |event_template|
      event_instances << event_template.next_event_instances(options)
    end
    event_instances.flatten.sort_by { |e| e.start_planned }
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

  def self.next_event_instance(event_type, begin_time = COLLECTION_TIME_PAST.ago, final_time= 2.months.from_now)
    event_instances = []
    event_instances = Event.where(category: event_type).map { |event|
      event.next_event_instance(begin_time, final_time)
    }.compact
    return nil if event_instances.empty?
    event_instances = event_instances.sort_by { |e| e.start_planned }
    return event_instances[0]
  end


  def next_event_instance(start = Time.now, final= 2.months.from_now)
    begin_datetime = start_datetime_for_collection(start_time: start)
    return EventInstance.new(title: self.name,
                       description: self.description,
                       duration_planned: self.duration,
                       category: self.category,
                       event_id: self.id,
                       start_planned: self.start_datetime) if repeats == 'never'
    final_datetime = repeating_and_ends? ? repeat_ends_on : final
    event_instance = nil
    occurrences = occurrences_between(start, final_datetime)
    EventInstance.new(title: self.name,
                description: self.description,
                duration_planned: self.duration,
                category: self.category,
                event_id: self.id,
                start_planned: occurrences.first.start_time) if occurrences.present?
  end

  def next_event_instances(options = {})
    begin_datetime = start_datetime_for_collection(options)
    final_datetime = final_datetime_for_collection(options)
    limit = options.fetch(:limit, 100)
    [].tap do |occurences|
      occurrences_between(begin_datetime, final_datetime).each do |time|
        occurences << EventInstance.new(title: self.name,
                                  description: self.description,
                                  duration_planned: self.duration,
                                  category: self.category,
                                  event_id: self.id,
                                  uid: EventInstance.generate_hangout_id(options[:current_user]),
                                  start_planned: time)
        return occurences if occurences.count >= limit
      end
    end
  end

#deprecated:  left over for old events index page.
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

#deprecated:  left over for old applications.event_link page.
  def next_occurrence_time_attr
    next_event_instance? ? next_event_instance.start : nil
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

  def remove_first_event_from_schedule
    next_occurrences = next_event_instances(limit: 2)
    if (next_occurrences.size > 1)
      self.start_datetime = next_occurrences[1].start_planned
    elsif (next_occurrences.size > 0)
      self.start_datetime = next_occurrences[0].start_planned + 1.day
    else
      return nil
    end
  end

  def remove_from_schedule(datetime)
    next_occurrences = next_event_instances(end_time: Time.now)
    while next_occurrences.size > 1 && datetime > next_occurrences[0].start_planned
      self.start_datetime = next_occurrences[1].start_planned
      next_occurrences = next_event_instances({end_time: Time.now})
    end
    if datetime == next_event_instance.start_planned
      remove_first_event_from_schedule
    else
      self.exclusions ||= []
      self.exclusions << datetime
    end
    save
    self
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
    self.exclusions ||= []
    self.exclusions.each do |ex|
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
    event_instances.order(:start).last
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
