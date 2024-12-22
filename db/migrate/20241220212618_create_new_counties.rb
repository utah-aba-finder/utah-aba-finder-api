class CreateNewCounties < ActiveRecord::Migration[7.1]
  def change
    create_table :counties do |t|
      t.string :name, null: false
      t.references :state, null: false, foreign_key: true
      t.timestamps
    end
  end
end
