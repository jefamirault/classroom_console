class AddSchoolYearsToSyncProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :sync_profiles, :school_year_id, :integer
  end
end
