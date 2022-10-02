class AddEnrollmentsCountToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :enrollments_count, :integer
  end
end
