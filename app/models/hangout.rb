class Hangout < ActiveRecord::Base
  belongs_to :event
  belongs_to :user
  include UserNullable
  belongs_to :project

  serialize :participants

  COLLECTION_TIME_FUTURE = 10.days
  COLLECTION_TIME_PAST = 15.minutes

  scope :started, -> { where.not(hangout_url: nil) }
  scope :not_expired, -> { where('start_planned > ?', 30.minutes.ago) }
  scope :pending, -> { where(hangout_url: nil) }
  scope :live, -> { where('heartbeat_gh > ?', 5.minutes.ago).order('created_at DESC') }
  scope :latest, -> { order('start_planned DESC') }

  def started?
    hangout_url.present?
  end

  def live?
    started? && heartbeat_gh.present? && heartbeat_gh > 5.minutes.ago
  end

  def duration
    heartbeat_gh - start_gh
  end

  def self.active_hangouts
    select(&:live?)
  end

  def start_datetime
    event != nil ? event.start_datetime : created_at
  end

  def self.live_event_instance(event_type, begin_time = COLLECTION_TIME_PAST.ago)
    event_instances = Hangout.started.live.latest
    return event_instances.first unless event_instances.empty?
  end

  def self.next_event_instance(event_type, begin_time = COLLECTION_TIME_PAST.ago)
    event_instances = Hangout.pending.not_expired.latest
    return event_instances.first unless event_instances.empty?
  end

  def self.generate_hangout_id(user, project_id = nil)
    return '' if user.nil?
    project_id ||= '00'
    "#{user.id}#{project_id}#{Time.now.to_i}"
  end
end
