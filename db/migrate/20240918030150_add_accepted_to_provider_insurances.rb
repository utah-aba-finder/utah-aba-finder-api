class AddAcceptedToProviderInsurances < ActiveRecord::Migration[7.1]
  def change
    add_column :provider_insurances, :accepted, :boolean
  end
end
