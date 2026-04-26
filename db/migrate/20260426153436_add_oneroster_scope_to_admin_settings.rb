class AddOnerosterScopeToAdminSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :admin_settings, :oneroster_scope, :string
  end
end
