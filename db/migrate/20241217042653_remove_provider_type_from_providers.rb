class RemoveProviderTypeFromProviders < ActiveRecord::Migration[7.1]
  def change
    remove_column :providers, :provider_type, :integer
  end
end
