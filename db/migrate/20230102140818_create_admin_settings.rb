class CreateAdminSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :admin_settings do |t|
      t.string :canvas_path
      t.string :canvas_access_token
      t.string :on_api_path
      t.string :on_api_username
      t.string :on_api_key
      t.string :on_api_secret
      t.integer :account_id
      t.string :sis_school_year
      t.integer :sis_level_num
      t.integer :sis_email_list_id
      t.integer :sis_teacher_enrollments_list_id

      t.timestamps
    end
  end
end
