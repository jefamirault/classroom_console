class UsersUniqueBySisId < ActiveRecord::Migration[7.0]
  def change
    remove_index :users, name: "index_users_on_email"
    add_index :users, :email, name: "index_users_on_email", unique: false

    add_index :users, :sis_id, unique: true, name: "index_users_on_sis_id"
  end
end
