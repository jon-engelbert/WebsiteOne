module HangoutsHelper
  def generate_hangout_id(user, project_id = nil)
    project_id ||= '00'
    "#{user.id}#{project_id}#{Time.now.to_i}"
  end

  def edit_upcoming_hangout_path(hangout)
    if hangout.id.present?
      edit_hangout_path(hangout.id)
    else
      tempPath= hangouts_edit_upcoming_unsaved_path(title: hangout.title,
                                                    start_planned: hangout.start_planned,
                                                    category: hangout.category,
                                                    description: hangout.description,
                                                    duration_planned: hangout.duration_planned,
                                                    event_id: hangout.event_id)
    end
  end
  def manage_upcoming_hangout_path(hangout)
    if hangout.id.present?
      manage_hangout_path(hangout.id)
    else
      tempPath= hangouts_manage_upcoming_unsaved_path(title: hangout.title,
                                                      start_planned: hangout.start_planned,
                                                      category: hangout.category,
                                                      description: hangout.description,
                                                      duration_planned: hangout.duration_planned,
                                                      event_id: hangout.event_id)

    end
  end
end