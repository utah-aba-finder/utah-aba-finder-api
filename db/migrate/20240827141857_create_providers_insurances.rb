class CreateProvidersInsurances < ActiveRecord::Migration[7.1]
  def change
    create_table :providers_insurances do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :insurance, null: false, foreign_key: true

      t.timestamps
    end
  end
end