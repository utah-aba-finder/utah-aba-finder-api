class CreateProviderAttributes < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_attributes do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :category_field, null: false, foreign_key: true
      t.text :value
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :provider_attributes, [:provider_id, :category_field_id], unique: true, name: 'index_provider_attributes_unique'
    add_index :provider_attributes, :value
  end
end
