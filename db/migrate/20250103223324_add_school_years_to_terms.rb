class AddSchoolYearsToTerms < ActiveRecord::Migration[7.0]
  def change
    add_column :terms, :school_year_id, :integer
  end
end
