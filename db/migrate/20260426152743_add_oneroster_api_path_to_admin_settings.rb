class AddOnerosterApiPathToAdminSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :admin_settings, :oneroster_api_path, :string
  end
end
