class CreateQuarantines < ActiveRecord::Migration[7.0]
  def change
    create_table :quarantines do |t|
      t.datetime :end
      t.integer :quarantinable_id
      t.string :quarantinable_type

      t.timestamps
    end
  end
end
