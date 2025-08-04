namespace :logos do
  desc "Migrate Cloudinary logo URLs to Active Storage"
  task migrate_to_active_storage: :environment do
    puts "Starting logo migration to Active Storage..."
    
    providers_with_cloudinary = Provider.where.not(logo: [nil, '']).where.not(logo: '')
    total_providers = providers_with_cloudinary.count
    migrated_count = 0
    failed_count = 0
    
    providers_with_cloudinary.find_each do |provider|
      begin
        # Skip if already has Active Storage attachment
        if provider.logo.attached?
          puts "Provider #{provider.id} (#{provider.name}) already has Active Storage logo - skipping"
          next
        end
        
        cloudinary_url = provider[:logo]
        puts "Migrating provider #{provider.id} (#{provider.name}) from: #{cloudinary_url}"
        
        # Download the image from Cloudinary
        require 'open-uri'
        require 'tempfile'
        
        # Create a temporary file
        temp_file = Tempfile.new(['logo', '.jpg'])
        temp_file.binmode
        
        # Download the image
        URI.open(cloudinary_url) do |remote_file|
          temp_file.write(remote_file.read)
        end
        
        temp_file.rewind
        
        # Attach to Active Storage
        provider.logo.attach(
          io: temp_file,
          filename: "logo_#{provider.id}.jpg",
          content_type: 'image/jpeg'
        )
        
        # Clear the old Cloudinary URL from the database
        provider.update_column(:logo, nil)
        
        migrated_count += 1
        puts "✅ Successfully migrated provider #{provider.id} (#{provider.name})"
        
      rescue => e
        failed_count += 1
        puts "❌ Failed to migrate provider #{provider.id} (#{provider.name}): #{e.message}"
      ensure
        temp_file&.close
        temp_file&.unlink
      end
    end
    
    puts "\n🎉 Migration complete!"
    puts "Total providers processed: #{total_providers}"
    puts "Successfully migrated: #{migrated_count}"
    puts "Failed: #{failed_count}"
  end
end 