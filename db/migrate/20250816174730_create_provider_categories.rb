class CreateProviderCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :is_active, default: true, null: false
      t.integer :display_order, default: 0

      t.timestamps
    end

    add_index :provider_categories, :slug, unique: true
    add_index :provider_categories, :is_active
    add_index :provider_categories, :display_order
  end
end
