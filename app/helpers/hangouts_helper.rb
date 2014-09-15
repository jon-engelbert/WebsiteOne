module HangoutsHelper
  def generate_hangout_id(user, project_id = nil)
    project_id ||= '00'
    "#{user.id}#{project_id}#{Time.now.to_i}"
  end

  def edit_unsaved_hangout_path(hangout)
    if hangout.id.present?
      edit_hangout_path(hangout.id)
    else
      tempPath= edit_hangouts_path(title: hangout.title,
                                   start_planned: hangout.start_planned,
                                   category: hangout.category,
                                   description: hangout.description,
                                   duration_planned: hangout.duration_planned,
                                   event_id: hangout.event_id)
    end
  end
end