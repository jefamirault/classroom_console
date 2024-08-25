class ChangeSubscriptions < ActiveRecord::Migration[7.0]
  def change
    remove_column :subscriptions, :email, :text
    remove_column :subscriptions, :user_id, :integer
    remove_column :subscriptions, :subscribed, :boolean

    change_table :subscriptions do |t|
      t.integer :section_sis_id
      t.integer :section_id
      t.integer :sync_profile_id
      t.boolean :enabled
      t.boolean :sis_enrollments
      t.boolean :maintain_canvas_section
      t.boolean :post_canvas_grades
    end
  end
end
