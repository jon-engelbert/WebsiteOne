class HookupsController < ApplicationController
  def index
    @pending_events = Event.pending_hookups
    @active_hangouts = Hangout.pp_hangouts.started.live
    @category = 'scrums'
  end

  def filter
    if (params['category'] == 'hookups')
      @pending_events = Event.pending_hookups
      @active_hangouts = Hangout.pp_hangouts.started.live
    elsif (params['category'] == 'scrums')
      @pending_events = Event.pending_scrums
      @active_hangouts = Hangout.scrum_hangouts.started.live
    elsif (params['category'] == 'hookups_and_scrums')
      pending_hookups = Event.pending_hookups
      pending_scrums = Event.pending_scrums
      @pending_events = []
      pending_hookups.each do |hookup|
        @pending_events << hookup
      end
      pending_scrums.each do |scrum|
        @pending_events << scrum
      end
      @active_hangouts = Hangout.started.live
    end
    @category = params['category']
    render :index
  end
end