class Hangout < ActiveRecord::Base
  belongs_to :event
  belongs_to :user
  include UserNullable
  belongs_to :project

  serialize :participants

  scope :started, -> { where.not(hangout_url: nil) }
  scope :live, -> { where('heartbeat_gh > ?', 5.minutes.ago).order('created_at DESC') }
  scope :latest, -> { order('created_at DESC') }

  def started?
    hangout_url?
  end

  def live?
    started? && heartbeat_gh > 5.minutes.ago
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
end
