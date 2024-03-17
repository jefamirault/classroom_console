class UsePermissionsForApiReadWrite < ActiveRecord::Migration[7.0]
  def change
    change_table :admin_settings do |t|
      t.boolean :allow_on_api_read, default: false
      t.boolean :allow_on_api_write, default: false
      t.boolean :allow_canvas_api_read, default: false
      t.boolean :allow_canvas_api_write, default: false
    end
  end
end
