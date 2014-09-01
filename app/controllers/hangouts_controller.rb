class HangoutsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :cors_preflight_check, except: [:index]

  def update
    hangout = Hangout.find_or_create_by(uid: params[:id])

    if hangout.try!(:update, hangout_params)
      SlackService.post_hangout_notification(hangout) if params[:notify] == 'true'

      redirect_to event_path(params[:event_id]) and return if local_request?
      head :ok
    else
      head :internal_server_error
    end
  end

  def index
    @hangouts = (params[:live] == 'true') ? Hangout.live : Hangout.all
    @events = Event.pending_hangouts
    @hangouts += @events
  end

  def new
    @hangout = Hangout.new(start_planned: Time.now.utc,
                           duration_planned: 30)
  end

  def show
    @hangout = Hangout.find_or_create_by(uid: params[:id])
  end

  def edit
  end

  def edit_uninstantiated
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

  private

  def cors_preflight_check
    head :bad_request and return unless (allowed? || local_request?)

    set_cors_headers
    head :ok and return if request.method == 'OPTIONS'
  end

  def allowed?
    allowed_sites = %w(a-hangout-opensocial.googleusercontent.com)
    origin = request.env['HTTP_ORIGIN']
    allowed_sites.any?{ |url| origin =~ /#{url}/ }
  end

  def local_request?
    request.remote_ip == '127.0.0.1'
  end

  def set_cors_headers
    response.headers['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN']
    response.headers['Access-Control-Allow-Methods'] = 'PUT'
  end

  def hangout_params
    params.require(:host_id)
    params.require(:title)

    ActionController::Parameters.new(
      title: params[:title],
      project_id: params[:project_id],
      event_id: params[:event_id],
      category: params[:category],
      user_id: params[:host_id],
      participants: params[:participants],
      hangout_url: params[:hangout_url],
      yt_video_id: params[:yt_video_id]).permit!

  end
end
