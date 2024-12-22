class RenameCountiesToOldCounties < ActiveRecord::Migration[7.1]
  def change
    rename_table :counties, :old_counties
  end
end
