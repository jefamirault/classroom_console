class CreateSections < ActiveRecord::Migration[6.0]
  def change
    create_table :sections do |t|
      t.string :name
      t.integer :sis_id
      t.integer :course_id
      t.integer :canvas_id
      t.integer :canvas_course_id
      t.integer :term_id

      t.timestamps
    end
  end
end
