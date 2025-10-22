namespace :mass_email do
  desc "Send password update reminders to all approved providers"
  task password_reminder: :environment do
    puts "🚀 Starting mass email campaign for password updates..."
    
    # Get all approved providers
    providers = Provider.where(status: :approved)
    total_providers = providers.count
    
    puts "📊 Found #{total_providers} approved providers"
    
    # Filter providers who have user accounts and likely need password updates
    # Only target providers with existing user accounts
    providers_needing_updates = providers.joins(:user).where(
      "providers.created_at < ?", 
      1.week.ago
    )
    
    puts "📧 #{providers_needing_updates.count} providers need password updates"
    
    # Send emails in batches to avoid overwhelming the system
    batch_size = 10
    sent_count = 0
    error_count = 0
    
    providers_needing_updates.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |provider|
        begin
          MassNotificationMailer.password_update_reminder(provider).deliver_now
          sent_count += 1
          puts "✅ Sent to: #{provider.name} (#{provider.email})"
        rescue => e
          error_count += 1
          puts "❌ Failed to send to #{provider.name}: #{e.message}"
        end
      end
      
      # Small delay between batches to be respectful to email servers
      sleep(2)
    end
    
    puts "\n🎉 Mass email campaign completed!"
    puts "📊 Results:"
    puts "  - Total providers: #{total_providers}"
    puts "  - Emails sent: #{sent_count}"
    puts "  - Errors: #{error_count}"
  end

  desc "Send system update notifications to all approved providers"
  task system_update: :environment do
    puts "🚀 Starting mass email campaign for system updates..."
    
    providers = Provider.where(status: :approved)
    total_providers = providers.count
    
    puts "📊 Found #{total_providers} approved providers"
    
    sent_count = 0
    error_count = 0
    
    providers.find_in_batches(batch_size: 10) do |batch|
      batch.each do |provider|
        begin
          MassNotificationMailer.system_update_notification(provider).deliver_now
          sent_count += 1
          puts "✅ Sent to: #{provider.name} (#{provider.email})"
        rescue => e
          error_count += 1
          puts "❌ Failed to send to #{provider.name}: #{e.message}"
        end
      end
      
      sleep(2)
    end
    
    puts "\n🎉 System update campaign completed!"
    puts "📊 Results:"
    puts "  - Total providers: #{total_providers}"
    puts "  - Emails sent: #{sent_count}"
    puts "  - Errors: #{error_count}"
  end

  desc "List providers who need password updates (dry run)"
  task list_providers: :environment do
    puts "📋 Providers who need password updates:"
    puts "=" * 50
    
    providers = Provider.where(status: :approved)
    providers_needing_updates = providers.joins(:user).where(
      "providers.created_at < ?", 
      1.week.ago
    )
    
    providers_needing_updates.each_with_index do |provider, index|
      user_status = provider.user ? "Has user account" : "No user account"
      puts "#{index + 1}. #{provider.name}"
      puts "   Email: #{provider.email}"
      puts "   Status: #{user_status}"
      puts "   Created: #{provider.created_at.strftime('%Y-%m-%d')}"
      puts
    end
    
    puts "Total: #{providers_needing_updates.count} providers need updates"
  end
end
