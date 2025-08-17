class CreateProviderAttributes < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_attributes do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :category_field, null: false, foreign_key: true
      t.text :value
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :provider_attributes, [:provider_id, :category_field_id], unique: true
    add_index :provider_attributes, :provider_id
    add_index :provider_attributes, :category_field_id
  end
end 