namespace :test do
  desc "Test Active Storage functionality"
  task active_storage: :environment do
    puts "Testing Active Storage functionality..."
    
    # Find a provider to test with
    provider = Provider.first
    puts "Testing with provider: #{provider.name} (ID: #{provider.id})"
    
    # Check current state
    puts "Current logo attached?: #{provider.logo.attached?}"
    puts "Current logo URL: #{provider.logo_url}"
    
    # Test manual attachment
    begin
      # Create a simple test image
      test_image_path = Rails.root.join('tmp', 'test_image.png')
      File.write(test_image_path, Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='))
      
      # Attach the test image
      provider.logo.attach(
        io: File.open(test_image_path),
        filename: "test_manual.png",
        content_type: "image/png"
      )
      
      provider.save!
      
      puts "✅ Manual attachment successful!"
      puts "Logo attached after?: #{provider.logo.attached?}"
      puts "New logo URL: #{provider.logo_url}"
      
      # Test URL generation
      begin
        url = Rails.application.routes.url_helpers.rails_blob_url(provider.logo)
        puts "✅ URL generation successful: #{url}"
      rescue => e
        puts "❌ URL generation failed: #{e.message}"
      end
      
    rescue => e
      puts "❌ Manual attachment failed: #{e.message}"
      puts e.backtrace.first(5)
    ensure
      # Clean up test file
      File.delete(test_image_path) if File.exist?(test_image_path)
    end
  end
end 