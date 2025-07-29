class AddServiceDeliveryToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :service_delivery, :json, default: { in_home: false, in_clinic: false, telehealth: false }
  end
end
