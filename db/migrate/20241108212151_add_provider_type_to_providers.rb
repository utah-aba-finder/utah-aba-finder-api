class AddProviderTypeToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :provider_type, :integer, default: 0, null: false
  end
end
