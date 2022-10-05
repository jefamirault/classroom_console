class SetDefaultValueForSectionsCount < ActiveRecord::Migration[7.0]
  def change
    change_column_default :sections, :enrollments_count, from: nil, to: 0
    change_column_default :users, :enrollments_count, from: nil, to: 0
    change_column_default :courses, :sections_count, from: nil, to: 0
  end
end
