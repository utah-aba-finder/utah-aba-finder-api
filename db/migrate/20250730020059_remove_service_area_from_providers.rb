class RemoveServiceAreaFromProviders < ActiveRecord::Migration[7.1]
  def change
    remove_column :providers, :service_area, :json
  end
end
