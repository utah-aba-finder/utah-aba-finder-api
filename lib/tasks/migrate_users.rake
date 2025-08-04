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
        users_data = JSON.parse(response.body)['users']
        puts "Found #{users_data.length} users to migrate"
        
        users_data.each do |user_data|
          email = user_data['email']
          
          # Skip if user already exists in new app
          existing_user = User.find_by(email: email)
          if existing_user
            puts "User #{email} already exists, skipping..."
            next
          end
          
          # For now, set all users as regular users (they can reset their password later)
          # We'll need to manually set super_admin roles for specific users
          new_role = 'user'
          
          # Set specific users as super_admin based on the old app data
          if ['williamsonjordan05@gmail.com', 'cheeleertr@gmail.com', 'austincarr.jones@gmail.com', 'jarvisbailey@autismserviceslocator.com', 'jenniferbixler@autismserviceslocator.com'].include?(email)
            new_role = 'super_admin'
          end
          
          # Create user in new app
          new_user = User.create!(
            email: email,
            password: 'TemporaryPassword123!', # They'll need to reset their password
            password_confirmation: 'TemporaryPassword123!',
            role: new_role,
            provider_id: nil # We'll need to set this manually if needed
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
      puts e.backtrace.join("\n")
    end
  end
end 