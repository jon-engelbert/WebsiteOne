class HangoutsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :cors_preflight_check, except: [:index]
  before_action :set_hangout, only: [:show, :edit, :update, :destroy]



  def index
    @hangouts = (params[:live] == 'true') ? Hangout.live : Hangout.all
    @hangouts_from_repeating_events = Event.pending_repeating_hangouts(10.hours.ago, 7.days.from_now, 3)
    @hangouts += @hangouts_from_repeating_events
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
    @hangout = Hangout.new(title: params[:title],
                           start_planned: temp_params[:start_planned],
                           duration_planned: temp_params['duration'],
                           category: temp_params['category'],
                           description: temp_params['description']
    )
    render edit_hangout_path(@hangout)
  end

  # creates an event instance (hangout model) if the event is non-repeating... otherwise creates an event series template (event)
  def create
    temp_params = params.require(:hangout).permit!
    temp_params[:start_planned] = "#{params['start_date']} #{params['start_time']} UTC"

      @hangout = Hangout.new(title: temp_params['title'],
                                  start_planned: temp_params[:start_planned],
                                  duration_planned: temp_params['duration'],
                                  category: temp_params['category'],
                                  description: temp_params['description']
      )
      if @hangout.save
        flash[:notice] = %Q{Successfully created the event "#{@hangout.title}!"}
        redirect_to hangouts_path
      else
        flash.now[:alert] = @hangout.errors.full_messages.join(', ')
        render 'new'
      end
  end

  # if not yet instatiated, i.e. coming from a recurring event instance, then create a new hangout.  Otherwise,
  def update
    temp_params = params.require(:hangout).permit!
    temp_params[:start_datetime] = "#{params['start_date']} #{params['start_time']} UTC"
    if !params['isInstantiated']
      @hangout = Hangout.new(title: temp_params['name'],
                             start_planned: temp_params[:start_datetime],
                             duration_planned: temp_params['duration'],
                             category: temp_params['category'],
                             description: temp_params['description']

      )
      if @hangout.save
        flash[:notice] = %Q{Successfully created the event "#{@hangout.title}!"}
        redirect_to events_path
      else
        flash.now[:alert] = @hangout.errors.full_messages.join(', ')
        render 'new'
      end
    else
      @hangout = Hangout.find(id: temp_params['id'])
      if @hangout.update_attributes(temp_params)
        flash[:notice] = 'Event Updated'
        redirect_to hangouts_path
      else
        flash[:alert] = ['Failed to update event:', @hangout.errors.full_messages].join(' ')
        redirect_to edit_hangout_path(@hangout)
      end
    end
  end

  def event_params
    temp_params = params.require(:event).permit!
    temp_params[:start_datetime] = "#{params['start_date']} #{params['start_time']} UTC"
    temp_params
  end
  def hangout_params
    temp_params = params.require(:hangout).permit!
    temp_params[:start_datetime] = "#{params['start_date']} #{params['start_time']} UTC"
    temp_params
  end

=begin
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
=end
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
    response.headers['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN'] if request.env['HTTP_ORIGIN'].present?
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
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_hangout
    @hangout = Hangout.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def hangout_params
    params.require(:hangout).permit(:title, :start_planned, :start_date, :start_time, :duration_planned, :description, :category)
  end
end
