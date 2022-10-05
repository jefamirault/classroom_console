class SetEnrollmentsCountDefaultToZero < ActiveRecord::Migration[7.0]
  def change
    Section.find_each do |s|
      Section.reset_counters s.id, :enrollments_count
    end
    change_column_null :sections, :enrollments_count, false
    User.find_each do |u|
      User.reset_counters u.id, :enrollments_count
    end
    change_column_null :users, :enrollments_count, false
    Course.find_each do |c|
      Course.reset_counters c.id, :sections_count
    end
    change_column_null :courses, :sections_count, false
  end
end
