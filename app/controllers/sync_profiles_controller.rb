class SyncProfilesController < ApplicationController
  def index
    @sync_profiles = SyncProfile.all
  end

  def show
    @sync_profile = SyncProfile.includes(:subscriptions).find(params[:id])
  end

  def new
    @sync_profile = SyncProfile.new
  end

  def create
    @sync_profile = SyncProfile.new(sync_profile_params)
    if @sync_profile.save
      redirect_to @sync_profile, notice: "Sync profile was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
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

  private

  def sync_profile_params
    params.require(:sync_profile).permit(:user_id, :school_year_id)
  end
end