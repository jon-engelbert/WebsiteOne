class AlphaEventsController < ApplicationController
  def index
    @alphaEvents = AlphaEvent.all
  end
end