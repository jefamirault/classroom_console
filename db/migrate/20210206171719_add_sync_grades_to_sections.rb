class AddSyncGradesToSections < ActiveRecord::Migration[6.0]
  def change
    add_column :sections, :sync_grades, :boolean
  end
end
