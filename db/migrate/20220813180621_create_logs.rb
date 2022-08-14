class CreateLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :logs do |t|
      t.integer :event_id
      t.integer :loggable_id
      t.string :loggable_type

      t.timestamps
    end
  end
end
