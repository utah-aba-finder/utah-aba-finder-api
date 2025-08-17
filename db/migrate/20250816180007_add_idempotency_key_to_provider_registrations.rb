class AddIdempotencyKeyToProviderRegistrations < ActiveRecord::Migration[7.1]
  def up
    puts "🔄 Adding idempotency key to provider registrations..."
    
    add_column :provider_registrations, :idempotency_key, :string
    add_index :provider_registrations, :idempotency_key, unique: true
    
    puts "✅ Idempotency key added successfully!"
  end

  def down
    puts "🔄 Rolling back idempotency key changes..."
    remove_index :provider_registrations, :idempotency_key
    remove_column :provider_registrations, :idempotency_key
    puts "✅ Idempotency key removed"
  end
end
