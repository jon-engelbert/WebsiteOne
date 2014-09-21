require 'custom_errors.rb'

class ApplicationController < ActionController::Base
  include YoutubeHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :static_page_path

  before_filter :get_next_scrum, :store_location
  before_action :configure_permitted_parameters, if: :devise_controller?

  include ApplicationHelper
  include CustomErrors

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:first_name, :last_name, :email, :bio, :password,
               :password_confirmation, :current_password,
               :display_email, :display_profile, :display_hire_me,
               :receive_mailings)
    end
  end

  def after_sign_in_path_for(resource)
    request.env['omniauth.origin'] || session[:previous_url] || root_path
  end

  private

  def black_listed_urls
    [
        user_session_path,
        new_user_registration_path,
        new_user_password_path,
        destroy_user_session_path,
        "#{edit_user_password_path}.*"
    ]
  end

  def black_listed_url?(blacklist)
    blacklist.any? { |pattern| request.path =~ %r(#{pattern}) }
  end

  def conventional_get_request?
    request.get? && !request.xhr?
  end

  def get_next_scrum
    next_event_instance_from_templates = Event.next_event_instance(:Scrum)
    live_event_instance = Hangout.live_event_instance(:Scrum)
    next_event_instance_from_instances = Hangout.next_event_instance(:Scrum)
    if live_event_instance.present?
      @next_event_instance = live_event_instance
    elsif next_event_instance_from_instances.present? && next_event_instance_from_templates.present? && next_event_instance_from_instances.start_planned < next_event_instance_from_templates.start_planned
      @next_event_instance = next_event_instance_from_instances
    elsif next_event_instance_from_templates.present?
      @next_event_instance = next_event_instance_from_templates
    end
    if @next_event_instance.present? && @next_event_instance.id.nil? && @next_event_instance.event.present?
      @next_event_instance.remove_from_template
      @next_event_instance.save!
    end
    @next_event_instance
  end

  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    if conventional_get_request? && !black_listed_url?(black_listed_urls)
      session[:previous_url] = request.fullpath
    end
  end
end
