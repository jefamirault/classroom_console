class DashboardController < ApplicationController

  before_action :authenticate_user!, if: -> { !demo_mode? }


  def index
    @grades = GradeChange.where(created_at: (Time.now - 24.hours)..Time.now).all
    @subscriptions = Subscription.where(enabled: true)
    @profiles = @subscriptions.map(&:sync_profile).uniq
  end
end