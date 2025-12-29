class AddPrimaryLocationIdToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :primary_location_id, :bigint
    add_index :providers, :primary_location_id
    add_foreign_key :providers, :locations, column: :primary_location_id, on_delete: :nullify
  end
end
