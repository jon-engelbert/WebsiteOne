class VisitorsController < ApplicationController
  include ApplicationHelper

  def index
    # disable countdown clock by setting @next_event to nil
    @event_instance = @next_event_instance
    @next_event_instance = nil

    render layout: false
  end
end
