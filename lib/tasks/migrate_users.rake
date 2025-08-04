namespace :migrate do
  desc "Migrate users from old app to new app"
  task users: :environment do
    puts "Starting user migration..."
    
    # Get users from old app via API
    old_app_url = "https://uta-aba-finder-be-97eec9f967d0.herokuapp.com"
    
    begin
      # Fetch all users from old app
      response = HTTParty.get("#{old_app_url}/api/v1/users")
      
      if response.success?
        users_data = JSON.parse(response.body)
        puts "Found #{users_data.length} users to migrate"
        
        users_data.each do |user_data|
          email = user_data['email']
          role = user_data['role']
          
          # Skip if user already exists in new app
          existing_user = User.find_by(email: email)
          if existing_user
            puts "User #{email} already exists, skipping..."
            next
          end
          
          # Convert role from integer to string
          new_role = case role
          when 0
            'user'
          when 1
            'super_admin'
          else
            'user'
          end
          
          # Create user in new app
          new_user = User.create!(
            email: email,
            password: 'TemporaryPassword123!', # They'll need to reset their password
            password_confirmation: 'TemporaryPassword123!',
            role: new_role,
            provider_id: user_data['provider_id']
          )
          
          puts "✅ Migrated user: #{email} (role: #{new_role})"
        end
        
        puts "\n🎉 User migration completed!"
        puts "Total users in new app: #{User.count}"
        
      else
        puts "❌ Failed to fetch users from old app: #{response.code}"
      end
      
    rescue => e
      puts "❌ Error during migration: #{e.message}"
    end
  end
end 