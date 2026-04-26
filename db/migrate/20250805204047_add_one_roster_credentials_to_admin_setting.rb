class AddOneRosterCredentialsToAdminSetting < ActiveRecord::Migration[7.0]
  def change
    add_column :admin_settings, :oneroster_key, :string
    add_column :admin_settings, :oneroster_secret, :string
  end
end
