class AddServiceDeliveryToProviders < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:providers, :service_delivery)
      add_column :providers, :service_delivery, :json, default: { in_home: false, in_clinic: false, telehealth: false }
    end
  end
end
