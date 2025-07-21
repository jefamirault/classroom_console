class RemoveObsoleteAdminSettings < ActiveRecord::Migration[7.0]
  def change
    remove_column :admin_settings, :sis_teacher_enrollments_list_id, :integer
    remove_column :admin_settings, :sis_email_list_id
  end
end
