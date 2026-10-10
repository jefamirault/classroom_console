# Lets an admin sign in as another user and return to their own session.
# While masquerading, current_user is the impersonated user and true_user is
# the admin who started it. "Admin" means a login_enabled user.
module Masquerading
  extend ActiveSupport::Concern

  SESSION_KEY = :masquerade_true_user_id

  included do
    helper_method :true_user, :masquerading?
  end

  private

  def true_user
    return current_user unless session[SESSION_KEY]
    @true_user ||= User.find_by(id: session[SESSION_KEY]) || current_user
  end

  def masquerading?
    session[SESSION_KEY].present? && current_user != true_user
  end

  def start_masquerade(user)
    admin = true_user
    session[SESSION_KEY] = admin.id
    sign_in :user, user
    log_masquerade 'Masquerade Start', "#{admin} started viewing as #{user}.", admin, user
  end

  def stop_masquerade
    admin = true_user
    user = current_user
    session.delete SESSION_KEY
    @true_user = nil
    sign_in :user, admin
    log_masquerade 'Masquerade Stop', "#{admin} stopped viewing as #{user}.", admin, user
  end

  def log_masquerade(label, description, admin, user)
    event = Event.make label, description
    [admin, user].uniq.each do |u|
      Log.create event_id: event.id, loggable_id: u.id, loggable_type: 'User'
    end
  end
end
