class SubscriptionsController < ApplicationController
  def create
    email = params[:email]
    @subscription = Subscription.find_by_email email
    success = "Thank you for your interest in Classroom Console! You have been added to our mailing list."
    if @subscription
    #  already subscribed
      flash[:message] = success
    else
      @subscription = Subscription.new email: email
      if @subscription.save
        flash[:message] = success
      else
        flash[:error] = 'Something went wrong'
      end
    end
  end
end