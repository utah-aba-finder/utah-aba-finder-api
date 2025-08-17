class AddProviderServiceTypes < ActiveRecord::Migration[7.1]
  def up
    puts "🚀 Adding support for multiple service types per provider..."
    
    # Create a join table for providers and their service types
    create_table :provider_service_types do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :provider_category, null: false, foreign_key: true
      t.boolean :is_primary, default: false
      t.jsonb :service_specific_data, default: {}
      t.timestamps
    end
    
    # Add unique constraint to prevent duplicate service types per provider
    add_index :provider_service_types, [:provider_id, :provider_category_id], unique: true, name: 'index_provider_service_types_unique'
    
    # Add index for primary service type lookups
    add_index :provider_service_types, [:provider_id, :is_primary]
    
    puts "✅ Created provider_service_types table"
    
    # Migrate existing data: set current category as primary service type
    puts "🔄 Migrating existing providers to new system..."
    
    # Get all providers with their current category
    providers_with_category = Provider.where.not(category: nil)
    
    providers_with_category.find_each do |provider|
      category = ProviderCategory.find_by(slug: provider.category)
      if category
        # Create primary service type from existing category
        provider.provider_service_types.create!(
          provider_category: category,
          is_primary: true,
          service_specific_data: {}
        )
        puts "✅ Migrated #{provider.name} to primary #{category.name}"
      end
    end
    
    puts "🎉 Migration completed! Providers can now have multiple service types."
  end

  def down
    puts "🔄 Rolling back provider service types..."
    
    # Remove the join table
    drop_table :provider_service_types
    
    puts "✅ Rollback completed"
  end
end 