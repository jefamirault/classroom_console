class AddLoginEnabledToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :login_enabled, :boolean, default: false, null: false
  end
end
