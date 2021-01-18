class CreateTenantVariables < ActiveRecord::Migration[6.0]
  def change
    create_table :tenant_variables do |t|
      t.string :name
      t.string :value

      t.timestamps
    end
  end
end
