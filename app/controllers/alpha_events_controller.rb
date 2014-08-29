class AlphaEventsController < ApplicationController
  def index
    @alphaEvents = AlphaEvent.all
  end
  def new
    @alpha_event = AlphaEvent.new
  end
  def create
    event_params = params[:alpha_event]
    event = AlphaEvent.new(title: event_params[:title],
                            start_planned: event_params[:start_planned],
                            tags: event_params[:tags],
                            agenda: event_params[:agenda],
                            comments: event_params[:comments])
    if event.save
      flash[:notice] = "Event has been created"
      redirect_to alpha_events_path
    end
  end
end

