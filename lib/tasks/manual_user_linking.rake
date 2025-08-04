namespace :users do
  desc "Manually link users to providers by email matching"
  task link_to_providers: :environment do
    puts "🔗 Manual User-Provider Linking Tool"
    puts "=" * 50
    
    # Get all users without provider_id
    unlinked_users = User.where(provider_id: nil)
    puts "📋 Found #{unlinked_users.count} users without provider_id"
    puts
    
    # Get all providers
    providers = Provider.all
    puts "🏢 Found #{providers.count} providers"
    puts
    
    # Create a mapping of provider emails to provider IDs
    provider_email_map = {}
    providers.each do |provider|
      if provider.email.present?
        provider_email_map[provider.email.downcase] = provider.id
      end
    end
    
    puts "🔍 Attempting to link users by email matching..."
    puts
    
    linked_count = 0
    unlinked_users.each do |user|
      # Try exact email match
      if provider_email_map[user.email.downcase]
        provider_id = provider_email_map[user.email.downcase]
        provider = Provider.find(provider_id)
        
        user.update!(provider_id: provider_id)
        puts "✅ Linked: #{user.email} → #{provider.name} (ID: #{provider_id})"
        linked_count += 1
      else
        # Try domain matching
        user_domain = user.email.split('@').last.downcase
        domain_providers = providers.select { |p| p.email&.downcase&.include?(user_domain.split('.').first) }
        
        if domain_providers.any?
          provider = domain_providers.first
          user.update!(provider_id: provider.id)
          puts "✅ Linked (domain): #{user.email} → #{provider.name} (ID: #{provider.id})"
          linked_count += 1
        else
          puts "❌ No match found for: #{user.email}"
        end
      end
    end
    
    puts
    puts "🎉 Linking complete!"
    puts "📊 Results:"
    puts "   - Total users processed: #{unlinked_users.count}"
    puts "   - Successfully linked: #{linked_count}"
    puts "   - Remaining unlinked: #{User.where(provider_id: nil).count}"
    puts
    
    # Show remaining unlinked users
    remaining_users = User.where(provider_id: nil)
    if remaining_users.any?
      puts "📝 Remaining unlinked users:"
      remaining_users.each do |user|
        puts "   - #{user.email} (ID: #{user.id})"
      end
      puts
      puts "💡 You can manually link these users using:"
      puts "   heroku run rails runner \"User.find(USER_ID).update!(provider_id: PROVIDER_ID)\" --app utah-aba-finder-api"
    end
  end
  
  desc "Manually link a specific user to a provider"
  task :link_user, [:user_id, :provider_id] => :environment do |task, args|
    user_id = args[:user_id]
    provider_id = args[:provider_id]
    
    if user_id.nil? || provider_id.nil?
      puts "❌ Usage: rake users:link_user[USER_ID,PROVIDER_ID]"
      puts "   Example: rake users:link_user[1,35]"
      exit 1
    end
    
    begin
      user = User.find(user_id)
      provider = Provider.find(provider_id)
      
      user.update!(provider_id: provider_id)
      puts "✅ Successfully linked: #{user.email} → #{provider.name} (ID: #{provider_id})"
    rescue ActiveRecord::RecordNotFound => e
      puts "❌ Error: #{e.message}"
    rescue => e
      puts "❌ Error: #{e.message}"
    end
  end
  
  desc "Show all users and their provider associations"
  task show_associations: :environment do
    puts "👥 User-Provider Associations"
    puts "=" * 40
    
    User.all.each do |user|
      provider = user.provider
      provider_info = provider ? "#{provider.name} (ID: #{provider.id})" : "None"
      puts "#{user.email} → #{provider_info}"
    end
  end
end 