class CreateCourses < ActiveRecord::Migration[6.0]
  def change
    create_table :courses do |t|
      t.string :name
      t.integer :sis_id
      t.boolean :is_active
      t.integer :course_length
      t.boolean :sync_course
      t.boolean :sync_grades

      t.timestamps
    end
  end
end
