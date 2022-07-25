class AddEnrollmentsCountToSection < ActiveRecord::Migration[6.0]
  def change
    add_column :sections, :enrollments_count, :integer
  end
end
