class CreateTerms < ActiveRecord::Migration[6.0]
  def change
    create_table :terms do |t|
      t.string :name
      t.integer :canvas_id
      t.datetime :start
      t.datetime :end

      t.timestamps
    end
  end
end
