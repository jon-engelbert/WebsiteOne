class HangoutPresenter < BasePresenter
  presents :hangout

  def created_at
    hangout.created_at.to_s(:time) if hangout.created_at.present?
  end

  def start_planned
    hangout.start_planned.to_s(:time) if hangout.start_planned.present?
  end

  def title
    hangout.title || 'No title given'
  end

  def category
    hangout.category || '-'
  end

  def project_link
    hangout.project ? link_to(hangout.project.title, url_helpers.project_path(hangout.project)) : '-'
  end

  def edit_link
    if (!hangout.id.present?)
      if (hangout.event.present?)
        hangout.save
        hangout.event.remove_from_schedule(hangout.start_planned)
      else
        '-'
      end
    end
    if (hangout.id.present?)
      link_to(hangout.title, url_helpers.edit_hangout_path(hangout), { class: "btn-hg-join #{hangout.live? ? '' : 'disable'}" })
    end
  end

  def show_link
    hangout.id.present? ? link_to(hangout.title, url_helpers.hangout_path(hangout)) : '-'
  end

  def event_link
    hangout.event ? link_to(hangout.event.name, url_helpers.event_path(hangout.event)) : '-'
  end

  def hangout_link
    hangout.id.present? ? link_to(hangout.title, url_helpers.hangout_path(hangout)) : '-'
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
      '#'
    end
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
