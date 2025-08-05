class SyncProfilesController < ApplicationController
  def index
    @sync_profiles = SyncProfile.all
  end

  def show
    @sync_profile = SyncProfile.includes(:subscriptions).find(params[:id])
  end

  def generate_subscriptions
    @sync_profile = SyncProfile.find(params[:sync_profile_id])
    created = @sync_profile.generate_subscriptions
    flash.notice = "Created #{created.count} subscriptions."
    redirect_to @sync_profile
  end

  def sync_now
    @sync_profile = SyncProfile.find(params[:sync_profile_id])
    @sync_profile.sync_now
    redirect_to @sync_profile
  end
end