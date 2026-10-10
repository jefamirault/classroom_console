# Passwordless sign-in for local development. Routes are only drawn in
# development, and the guard below is a second line of defense.
class DevLoginsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  before_action :require_development

  DEV_ADMIN_EMAIL = 'dev-admin@example.com'

  def index
    @users = User.order(login_enabled: :desc, name: :asc)
  end

  def create
    user = params[:user_id] ? User.find(params[:user_id]) : dev_admin
    session.delete Masquerading::SESSION_KEY
    sign_in :user, user
    redirect_to dashboard_path
  end

  private

  def require_development
    raise ActionController::RoutingError, 'Not Found' unless Rails.env.development?
  end

  def dev_admin
    User.where(login_enabled: true).order(:id).first ||
      User.create!(name: 'Dev Admin', email: DEV_ADMIN_EMAIL, login_enabled: true,
                   password: SecureRandom.hex(32))
  end
end
