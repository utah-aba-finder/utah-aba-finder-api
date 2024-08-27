class RenameProviderInsurancesToProvidersInsurance < ActiveRecord::Migration[7.1]
  def change
    rename_table :provider_insurance, :providers_insurance
  end
end
