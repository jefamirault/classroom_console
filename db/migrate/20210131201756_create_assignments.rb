class CreateAssignments < ActiveRecord::Migration[6.0]
  def change
    create_table :assignments do |t|
      t.integer :sis_id
      t.integer :section_id
    end
  end
end
