class DropProviderInsuranceTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :provider_insurance
  end
end
