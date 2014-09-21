class HangoutPresenter < BasePresenter
  presents :hangout

  def start_time
    hangout.start_gh.present? ? hangout.start_gh.strftime('%H:%M-UTC %d/%m') : hangout.start_planned.strftime('%H:%M-UTC %d/%m')
  end

  def title
    hangout.title || 'No title given'
  end

  def itself
    hangout
  end

  def category
    hangout.category || '-'
  end

  def live?
    hangout.live?
  end

  def started?
    hangout.started?
  end

  def project_link
    hangout.project ? link_to(hangout.project.title, url_helpers.project_path(hangout.project)) : '-'
  end

  def edit_event_link
    hangout.event ? url_helpers.edit_event_path(hangout.event) : '-'
  end

  def host
    hangout.user || NullUser.new('Anonymous')
  end

  def participants
    map_to_users(hangout.participants)
  end

  def video_url
    if id = hangout.yt_video_id
      "http://www.youtube.com/watch?v=#{id}&feature=youtube_gdata".html_safe
    else
      ''
    end
  end

  def duration
    distance_of_time_in_words(hangout.duration)
  end

  private

  def map_to_users(participants)
    participants ||= []

    participants.map do |participant|
      person = participant.last[:person]
      user = Authentication.find_by(provider: 'gplus', uid: person[:id]).try!(:user)
      next if user == host
      user || NullUser.new(person[:displayName])
    end.compact
  end

end
