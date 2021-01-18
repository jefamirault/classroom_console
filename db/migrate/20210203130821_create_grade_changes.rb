class CreateGradeChanges < ActiveRecord::Migration[6.0]
  def change
    create_table :grade_changes do |t|
      t.integer :enrollment_id
      t.float :old_value
      t.float :new_value
      t.datetime :time
      t.timestamps

      t.integer :previous_change_id
      t.integer :next_change_id
    end

    add_column :enrollments, :last_grade_change_id, :integer
  end
end
