class EventsController < ApplicationController
  def index
    @events = Event.all.order created_at: :desc
  end

  def show
    @event = Event.find params[:id]
  end
end