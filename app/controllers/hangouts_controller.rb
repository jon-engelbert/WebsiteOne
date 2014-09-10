class HangoutsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :cors_preflight_check, except: [:index]
  before_action :set_hangout, only: [:show, :edit, :update]

  def update
    is_created = false
    hangout = Hangout.find(uid: params[:id])
    if !hangout.present?
      begin
        hangout = Hangout.create(hangout_params)
      rescue
        attr_error = "hangout not saved, attributes invalid"
      end
      is_created = hangout.present?
    end

    if (hangout.present?)
      begin
        updated = hangout.update_attributes(hangout_params)
      rescue
        attr_error = "hangout not saved.  attributes invalid"
      end
    end

    if updated || is_created
      #hangout.event.remove_first_event_from_schedule() if hangout.event.present?
      hangout.event.remove_from_schedule(params[:start_planned]) if params[:start_planned].present?
      SlackService.post_hangout_notification(hangout) if params[:notify] == 'true'
      redirect_to(hangout_path params[:id]) && return if local_request? && params[:event_id].present?
      head :ok
    else
      flash[:alert] = ['Failed to save hangout:', hangout.errors.full_messages, attr_error].join(' ')
      head :internal_server_error
    end
  end

  def index
    @hangouts = (params[:live] == 'true') ? Hangout.live : Hangout.latest
    @hangouts += Event.pending_repeating_hangouts
    render partial: 'hangouts' if request.xhr?
  end

  def new
    @hangout = Hangout.new(start_planned: Time.now.utc,
                           duration_planned: 30)
  end

  def edit
  end

  def show
    @event = @hangout.event
    @event_schedule = @event.next_occurrences_with_time
    render partial: 'hangouts_management' if request.xhr?
  end

  def edit_upcoming_unsaved
    ho_params = {}
    ho_params[:title] = params[:title]
    ho_params[:start_planned] = params[:start_planned]
    ho_params[:category] = params[:category]
    ho_params[:description] = params[:description]
    ho_params[:duration_planned] = params[:duration_planned]
    @hangout = Hangout.new(ho_params)
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
      flash[:notice] = %Q{Created Event "#{@hangout.title}!"}
      redirect_to hangouts_path
    else
      flash.now[:alert] = @hangout.errors.full_messages.join(', ')
      render 'new'
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
    response.headers['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN'] if request.env['HTTP_ORIGIN'].present?
    response.headers['Access-Control-Allow-Methods'] = 'PUT'
  end

  def hangout_params
    params.require(:host_id)
    params.require(:title)
#    params.require(:hangout).permit(:title, :start_planned, :start_date, :start_time, :duration_planned, :description, :category)

    ActionController::Parameters.new(
      title: params[:title],
      project_id: params[:project_id],
      event_id: params[:event_id],
      category: params[:category],
      user_id: params[:host_id],
      participants: params[:participants],
      hangout_url: params[:hangout_url],
      yt_video_id: params[:yt_video_id],
      start_gh: Time.now,
      heartbeat_gh: Time.now
    ).permit!

  end

  # Use callbacks to share common setup or constraints between actions.
  def set_hangout
    @hangout = (params[:id].present? && (params[:id].is_a? Numeric)) ? Hangout.find(params[:id]) : nil
  end
end
