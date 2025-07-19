class AddSisIdToSchoolYears < ActiveRecord::Migration[7.0]
  def up
    add_column :school_years, :sis_id, :integer
    add_index :school_years, [:sis_id, :name], unique: true
  end

  def down
    remove_column :school_years, :sis_id, :integer
    change_column :school_years, :name, :string
  end
end
