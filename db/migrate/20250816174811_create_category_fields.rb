class CreateCategoryFields < ActiveRecord::Migration[7.1]
  def change
    create_table :category_fields do |t|
      t.references :provider_category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :field_type, null: false # text, textarea, select, checkbox, radio, boolean
      t.boolean :required, default: false
      t.jsonb :options, default: {}
      t.integer :display_order, default: 0
      t.text :help_text
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :category_fields, [:provider_category_id, :display_order]
    add_index :category_fields, :is_active
    add_index :category_fields, :field_type
  end
end
