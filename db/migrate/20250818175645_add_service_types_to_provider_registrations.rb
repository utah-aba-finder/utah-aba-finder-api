class AddServiceTypesToProviderRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_column :provider_registrations, :service_types, :string, array: true, default: []
  end
end
