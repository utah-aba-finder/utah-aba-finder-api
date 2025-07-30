class ConvertServiceDeliveryToJsonb < ActiveRecord::Migration[7.1]
  def up
    change_column :providers, :service_delivery, :jsonb, using: 'service_delivery::jsonb'
  end

  def down
    change_column :providers, :service_delivery, :json, using: 'service_delivery::json'
  end
end
