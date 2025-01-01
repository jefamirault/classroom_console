class RemoveOldColumns < ActiveRecord::Migration[7.0]
  def change
    remove_column :courses, :sync_grades, :boolean
    remove_column :sections, :sync_grades, :boolean
  end
end
