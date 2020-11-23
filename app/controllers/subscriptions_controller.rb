class SubscriptionsController < ApplicationController
  def create
    email = params[:email]
    @subscription = Subscription.find_by_email email
    if @subscription
    #  already subscribed
    else
      @subscription = Subscription.new email: email
      @subscription.save
    end
  end
end