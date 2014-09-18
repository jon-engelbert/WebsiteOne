class Event < ActiveRecord::Base
  has_many :hangouts
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

  def self.hookups
    Event.where(category: "PairProgramming")
  end

  def self.repeating_event_templates
    Event.where(:repeats != 'never')
  end

  # def self.pending_repeating_hangouts(options = {})
  #   repeating_event_instances = []
  #   repeating_event_templates.each do |repeating_event_template|
  #     repeating_event_instances << repeating_event_template.next_event_instances(options)
  #   end
  #   repeating_event_instances.flatten.sort_by { |e| e.start_planned }
  # end
  #
  def self.pending_hangouts_create_first(options = {})
    event_instances = []
    Event.all.each do |event_template|
      event_instances << event_template.next_event_instances(options)
    end
    event_instances = event_instances.flatten.sort_by { |e| e.start_planned }
    event_instances.each do |event_instance|
      if event_instance.start_planned < 6.hours.from_now
        event_instance.uid = Hangout.generate_hangout_id(options[:current_user], event_instance.project_id)
        event_instance.save!
        event_instance.event.remove_from_schedule(event_instance.start_planned, options[:start_time])
      end
    end
    event_instances
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
    }
    return nil if event_instances.empty?
    event_instances = event_instances.sort_by { |e| e.start_planned }
    return event_instances[0]
  end

  # The IceCube Schedule's occurrences_between method requires a time range as input to find the next time
  # Most of the time, the next instance will be within the next weeek.do
  # But some event instances may have been excluded, so there's not guarantee that the next time for an event will be within the next week, or even the next month
  # To cover these cases, the while loop looks farther and farther into the future for the next event occurrence, just in case there are many exclusions.
  def next_event_instance(start = Time.now, final= 2.months.from_now)
    begin_datetime = start_datetime_for_collection(start_time: start)
    return Hangout.new(title: self.name,
                       duration_planned: self.duration,
                       category: self.category,
                       event_id: self.id,
                       uid: Hangout.generate_hangout_id(current_user),
                       start_planned: self.start_datetime) if repeats == 'never'
    final_datetime = repeating_and_ends? ? repeat_ends_on : final
    n_days = 8
    end_datetime = n_days.days.from_now
    event_instance = nil
    occurrences = occurrences_between(start, final_datetime)
    Hangout.new(title: self.name,
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
        occurences << Hangout.new(title: self.name,
                                  duration_planned: self.duration,
                                  category: self.category,
                                  event_id: self.id,
                                  uid: Hangout.generate_hangout_id(options[:current_user]),
                                  start_planned: time)
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

  def remove_first_event_from_schedule
    _next_occurrences = next_event_instances(limit: 2)
    self.start_datetime = (_next_occurrences.size > 1) ? _next_occurrences[1].start_planned : _next_occurrences[0].start_planned + 1.day
  end

  def remove_from_schedule(timedate, start_time = Time.now)
    # best if schedule is serialized into the events record...  and an attribute.
    if timedate >= start_time && timedate == next_event_instance.start_planned
      remove_first_event_from_schedule
    elsif timedate >= start_time
      self.exclusions ||= []
      self.exclusions << timedate
    end
    save!
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
