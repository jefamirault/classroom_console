class AddLastSyncToSections < ActiveRecord::Migration[6.0]
  def change
    add_column :sections, :last_sync, :datetime
  end
end
