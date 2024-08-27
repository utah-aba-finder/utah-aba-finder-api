class CreateProviderInsurances < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_insurances do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :insurance, null: false, foreign_key: true

      t.timestamps
    end
  end
end
