class AddSectionsCountToCourses < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :sections_count, :integer
  end
end
