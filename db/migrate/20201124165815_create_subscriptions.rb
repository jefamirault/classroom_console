class CreateSubscriptions < ActiveRecord::Migration[6.0]
  def change
    create_table :subscriptions do |t|
      t.text :email
      t.integer :user_id
      t.boolean :subscribed

      t.timestamps
    end
  end
end
