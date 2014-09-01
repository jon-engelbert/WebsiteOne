class HookupsController < ApplicationController
  def new
    @hangout = Hangout.new(planned_start: Time.now.utc, planned_duration: 30)
  end

  def index
    @pending_hookups = Event.pending_hookups
    @active_pp_hangouts = Hangout.pp_hangouts.started.live
  end

  def edit
  end

  def editUninstantiated
    @hangout = Hangout.new(planned_start: Time.now.utc, planned_duration: 30)
    render edit_hangout_path(@hangout)
  end

  # creates an event instance (hangout model) if the event is non-repeating... otherwise creates an event series template (event)
  def create
    @event_instance = Hangout.new(title: event_params['name'],
                                  start_planned: event_params[:start_datetime],
                                  duration_planned: event_params['duration'],
                                  category: event_params['category'],
                                  description: event_params['description']
    )
    if @event_instance.save
      flash[:notice] = %Q{Successfully created the event "#{@event_instance.title}!"}
      redirect_to events_path
    else
      flash.now[:alert] = @event_instance.errors.full_messages.join(', ')
      render 'new'
    end
    if (event_params[:repeats] != 'never')
      EventCreatorService.new(Event).perform(event_params,
                                             success: ->(event) do
                                               @event = event
                                               flash[:notice] = 'Event Created'
                                               redirect_to event_path(@event)
                                             end,
                                             failure: ->(event) do
                                               @event = event
                                               flash[:notice] = @event.errors.full_messages.to_sentence
                                               render :new
                                             end)
    end
  end

  # if not yet instatiated, i.e. coming from a recurring event instance, then create a new hangout.  Otherwise,
  def update
    if !params['isInstantiated']
      @hangout = Hangout.new(title: event_params['name'],
                                    start_planned: event_params[:start_datetime],
                                    duration_planned: event_params['duration'],
                                    category: event_params['category'],
                                    description: event_params['description']

      )
      if @event_instance.save
        flash[:notice] = %Q{Successfully created the event "#{@hangout.title}!"}
        redirect_to events_path
      else
        flash.now[:alert] = @hangout.errors.full_messages.join(', ')
        render 'new'
      end
    else
      @event_instance = Hangout.find(id: event_params['id'])
      if @event_instance.update_attributes(event_params)
        flash[:notice] = 'Event Updated'
        redirect_to events_path
      else
        flash[:alert] = ['Failed to update event:', @event.errors.full_messages].join(' ')
        redirect_to edit_event_path(@event)
      end
    end
  end
end
