class EventPresenter < BasePresenter
  presents :event_object

  def created_at
    event_object.start_datetime.to_s(:time)
  end

  def title
    event_object.name || 'No title given'
  end

  def category
    event_object.category || '-'
  end

  def project
    '-'
  end

  def event
    link_to(event_object.name, url_helpers.event_path(event_object))
  end

  def host
    NullUser.new('Anonymous')
  end

  def participants
    []
  end

  def video_url
    '#'
  end

  def hangout_url
    '-'
  end

end
