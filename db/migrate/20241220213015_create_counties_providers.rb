class CreateCountiesProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :counties_providers, id: false do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :county, null: false, foreign_key: true
      t.timestamps
    end

    add_index :counties_providers, [:provider_id, :county_id], unique: true
  end
end
