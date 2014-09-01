class HookupsController < ApplicationController
  def new
    @hangout = Hangout.new(planned_start: Time.now.utc, planned_duration: 30)
  end

  def index
    @pending_hookups = Event.pending_hookups
    @active_pp_hangouts = Hangout.pp_hangouts.started.live
  end

  def create
  end
end
