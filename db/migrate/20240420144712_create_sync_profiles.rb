class CreateSyncProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :sync_profiles do |t|
      t.integer :user_id
      t.integer :term_id

      t.timestamps
    end
  end
end
