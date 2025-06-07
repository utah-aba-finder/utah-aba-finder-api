class CreateJoinTableLocationPracticeType < ActiveRecord::Migration[7.1]
  def change
    create_table :locations_practice_types do |t|
      t.references :location, null: false, foreign_key: true
      t.references :practice_type, null: false, foreign_key: true

      t.timestamps
    end

    add_index :locations_practice_types, [:location_id, :practice_type_id], unique: true, name: 'index_location_practice_type_on_location_and_practice_type'
  end
end
