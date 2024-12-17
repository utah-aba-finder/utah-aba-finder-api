class CreateStates < ActiveRecord::Migration[7.1]
  def change
    create_table :states do |t|
      t.string :name, null: false
      t.string :abbreviation, null: false

      t.timestamps
    end
  end
end
