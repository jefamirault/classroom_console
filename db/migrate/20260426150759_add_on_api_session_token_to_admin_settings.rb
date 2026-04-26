class AddOnApiSessionTokenToAdminSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :admin_settings, :on_api_session_token, :string
    add_column :admin_settings, :on_api_session_token_expires_at, :datetime
  end
end
