class MasqueradesController < ApplicationController
  before_action :require_admin

  def create
    user = User.find params[:user_id]
    if user == true_user
      stop_masquerade if masquerading?
    else
      start_masquerade user
    end
    redirect_to user_path(user)
  end

  def destroy
    user = current_user
    stop_masquerade if masquerading?
    redirect_to user_path(user)
  end

  private

  def require_admin
    head :forbidden unless true_user&.login_enabled
  end
end
