class CreateCounties < ActiveRecord::Migration[7.1]
  def change
    create_table :counties do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :counties_served

      t.timestamps
    end
  end
end
