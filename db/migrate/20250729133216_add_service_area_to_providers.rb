class AddServiceAreaToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :service_area, :json, default: { states_served: [], counties_served: [] }
  end
end
