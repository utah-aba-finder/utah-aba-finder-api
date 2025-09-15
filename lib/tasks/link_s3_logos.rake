namespace :logos do
  desc "Link existing S3 logos to providers"
  task link_s3_logos: :environment do
    puts "Starting S3 logo linking process..."
    
    # AWS credentials should be set as environment variables
    # This task requires AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION to be set
    
    # Mapping of S3 logo filenames to provider name patterns
    logo_mappings = {
      'ABS-Kids-logo.svg' => 'ABS Kids',
      'Affinity-autism-logo.webp' => 'Affinity Autism Services',
      'aba-with-iris.png' => 'ABA with Iris',
      'above-and-beyond-therapy.webp' => 'Above & Beyond Therapy',
      'aces-autism-logo.png' => 'ACES ABA',
      'achieving-autism-logo.webp' => 'Achieving Abilities LLC',
      'ages-autism-logo.png' => 'A.G.E.S. Learning Solutions',
      'autism-therapy-services-logo.png' => 'Autism Therapy Services',
      'bridgecare-aba.png' => 'A BridgeCare ABA',
      'utah-behavior-aba-logo.png' => 'Utah Behavior Services',
      'utah-autism-academy-logo.png' => 'Utah Autism Academy',
      'rogue-behavior-services-logo.png' => 'Rogue Behavior Services',
      'aba-pediatric-autism-services-logo.png' => 'ABA Pediatric Autism Services'
    }
    
    linked_count = 0
    
    logo_mappings.each do |filename, provider_name|
      provider = Provider.find_by(name: provider_name)
      
      if provider
        # Check if provider already has a logo
        if provider.logo.attached?
          puts "Provider '#{provider_name}' already has a logo, skipping..."
          next
        end
        
        # Create Active Storage blob and attachment
        begin
          # Create a blob record pointing to the S3 file
          blob = ActiveStorage::Blob.create!(
            key: "logos/#{filename}",
            filename: filename,
            content_type: Mime::Type.lookup_by_extension(File.extname(filename)[1..-1])&.to_s || 'image/png',
            metadata: {},
            service_name: 'amazon'
          )
          
          # Attach the blob to the provider
          provider.logo.attach(blob)
          
          puts "✅ Linked logo '#{filename}' to provider '#{provider_name}'"
          linked_count += 1
        rescue => e
          puts "❌ Failed to link logo '#{filename}' to provider '#{provider_name}': #{e.message}"
        end
      else
        puts "⚠️  Provider '#{provider_name}' not found, skipping logo '#{filename}'"
      end
    end
    
    puts "\n🎉 Logo linking complete! Linked #{linked_count} logos to providers."
  end
end
