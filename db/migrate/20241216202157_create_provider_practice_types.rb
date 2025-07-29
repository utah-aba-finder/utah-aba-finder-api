class CreateProviderPracticeTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_practice_types do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :practice_type, null: false, foreign_key: true

      t.timestamps
    end

    # Ensure unique combinations of provider and practice_type
    add_index :provider_practice_types, [:provider_id, :practice_type_id], unique: true
  end
end
