class CreateEnrollments < ActiveRecord::Migration[6.0]
  def change
    create_table :enrollments do |t|
      t.integer :user_id
      t.integer :section_id
      t.boolean :enrolled_in_canvas
      t.float :grade
      t.integer :role
    end
  end
end
