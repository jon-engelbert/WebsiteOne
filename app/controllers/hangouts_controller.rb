class HangoutsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :cors_preflight_check, only: [:update_from_gh]
  before_action :set_hangout, only: [:manage, :edit, :update]
  before_action :authenticate_user!, except: [:index, :update_from_gh]

  def update_from_gh
    is_created = false
    begin
      @hangout = Hangout.find_by(uid: params[:id])
    rescue
    end
    begin
      if !@hangout.present?
        @hangout = Hangout.create(hangout_params_from_gh)
        is_created = @hangout.present?
      else
        is_updated = @hangout.update_attributes(heartbeat_gh: Time.now, hangout_url: params[:hangout_url])
      end
    rescue
      attr_error = "Invalid hangout attributes."
    end
    if is_created || is_updated
      SlackService.post_hangout_notification(@hangout) if params[:notify] == 'true' && is_created
      redirect_to(manage_hangout_path params[:hangout_id]) && return if local_request? && params[:hangout_id].present?
      head :ok
    else
      head :internal_server_error
    end
  end

  def update_only_url
    is_created = false
    begin
      @hangout = Hangout.find(params[:id])
    rescue
    end
    begin
      if !@hangout.present?
        @hangout = Hangout.create(hangout_params_from_manage)
        is_created = @hangout.present?
      else
        is_updated = @hangout.update_attributes(hangout_params_from_manage)
      end
    rescue
      attr_error = "Invalid hangout attributes.  You have to provide a valid hangout url."
    end

    if is_updated || is_created
      @hangout.remove_from_template if @hangout.event.present? && params[:start_planned].present?
      flash[:notice] = 'Event URL has been updated'
      # Need to ask Yaro why this was here in the first place.
      # redirect_to(hangouts_path) && return if local_request?
      redirect_to(hangouts_path)
    else
      flash[:alert] = ['Failed to save hangout:', attr_error]
      if (@hangout.id)
        redirect_to manage_hangout_path(@hangout.id)
      end
    end
  end

  def update
    is_created = false
    begin
      @hangout = Hangout.find(params[:id])
    rescue
    end
    begin
      if !@hangout.present?
        @hangout = Hangout.create(hangout_params_from_form)
        is_created = @hangout.present?
      else
        is_updated = @hangout.update_attributes(hangout_params_from_form)
      end
    rescue
      attr_error = "Invalid hangout attributes."
    end

    if is_updated || is_created
      #hangout.event.remove_first_event_from_schedule() if hangout.event.present?
      if event_id_from_form.present? && start_original_from_form.present?
        @hangout.event_id = event_id_from_form
        @hangout.remove_from_template(start_original_from_form) if @hangout.event.present?
      end
      redirect_to(hangouts_path)
    else
      flash[:alert] = ['Failed to save hangout:', attr_error]
      if @hangout.present? && @hangout.id.present?
        redirect_to edit_from_template
      else
        redirect_to edit_from_template_hangouts_path
      end
    end
  end

  def index
    @hangouts = []
    Event.create_hangouts_if_upcoming(current_user, 3.hours.from_now)
    @hangouts += Event.pending_hangouts({ start_time: 3.hours.ago, current_user: current_user }) unless (params[:kill_pending] == 'true')
    @hangouts += (params[:live] == 'true') ? Hangout.live : Hangout.started_after(48.hours.ago).latest
    @hangouts = @hangouts.sort_by { |hangout|
      if hangout.start_gh.present?
        hangout.start_gh
      else
        hangout.start_planned
      end
    }
    render partial: 'hangouts' if request.xhr?
  end

  def new
    @hangout = Hangout.new(start_planned: Time.now.utc,
                           duration_planned: 30)
  end

  def edit
    @hangout = Hangout.find(params[:id])
  end

  def manage
    @hangout = Hangout.find(params[:id])
    render partial: 'hangouts_management' if request.xhr?
  end

  def edit_from_template
    event_id = params[:event_id]
    event = Event.find(event_id)
    if event.nil?
      flash[:notice] = "Can't find event"
      redirect_to hangouts_path
    end
    params[:title] = event.name
    params[:start_planned] = event.start_datetime
    params[:category] = event.category
    params[:description] = event.description
    params[:duration_planned] = event.duration
    params[:event_id] = event.id
    @hangout = Hangout.new(hangout_params_from_table)
    render 'new'
  end

  # creates an event instance (hangout model) if the event is non-repeating... otherwise creates an event series template (event)
  def create
    begin
      @hangout = Hangout.create(hangout_params_from_form)
    rescue
      attr_error = "Invalid hangout attributes."
    end
    if @hangout.present?
      flash[:notice] = %Q{Created Event "#{@hangout.title}!"}
      @hangout.remove_from_template(start_original_from_form) if @hangout.event.present? && start_original_from_form.present?
      redirect_to(hangouts_path)
    else
      flash.now[:alert] = attr_error
      @hangout = Hangout.new(hangout_params_from_form)
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
    allowed_sites.any? { |url| origin =~ /#{url}/ }
  end

  def local_request?
    request.remote_ip == '127.0.0.1'
  end

  def set_cors_headers
    response.headers['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN'] if request.env['HTTP_ORIGIN'].present?
    response.headers['Access-Control-Allow-Methods'] = 'PUT'
  end

  # this is called from the callback from Google Hangouts
  def hangout_params_from_gh
    params.require(:title)
    ActionController::Parameters.new(
        title: params[:title],
        category: params[:category],
        project_id: params[:projectId],
        event_id: params[:eventId],
        user_id: params[:hostId],
        uid: params[:id],
        start_gh: Time.now,
        heartbeat_gh: Time.now,
        start_planned: Time.now,
        hangout_url: params[:hangout_url]
    ).permit!
  end

  def hangout_params_from_form
    ho_params = params.require(:hangout).permit!
    ho_params.require(:title)
    if (params['start_date'].present? && params['start_time'].present?)
      ho_params[:start_planned] = "#{params['start_date']} #{params['start_time']} UTC"
    end
    ActionController::Parameters.new(
        title: ho_params[:title],
        start_planned: ho_params[:start_planned],
        description: ho_params[:description],
        duration_planned: ho_params[:duration],
        category: ho_params[:category],
        event_id: params[:event_id],
        uid: Hangout.generate_hangout_id(current_user, params[:project_id]),
    ).permit!
  end

  def start_original_from_form
    params[:start_original]
  end

  def hangout_params_from_table
    ActionController::Parameters.new(
        event_id: params[:event_id],
        title: params[:title],
        start_planned: params[:start_planned],
        category: params[:category],
        description: params[:description],
        user_id: params[:host_id],
        duration_planned: params[:duration_planned],
        uid: Hangout.generate_hangout_id(current_user),
    ).permit!
  end

  def hangout_params_from_manage
    ActionController::Parameters.new(
        event_id: params[:event_id],
        title: params[:title],
        start_planned: params[:start_planned],
        category: params[:category],
        description: params[:description],
        duration_planned: params[:duration_planned],
        hangout_url: params[:hangout_url],
        heartbeat_gh: Time.now,
        start_gh: Time.now

    ).permit!
  end

  def set_hangout
    @hangout = (params[:id].present? && (params[:id].is_a? Numeric)) ? Hangout.find(params[:id]) : nil
  end
end