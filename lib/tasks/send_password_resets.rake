namespace :password_reset do
  desc "Send password reset emails to all migrated users"
  task send_to_all: :environment do
    puts "Starting password reset email campaign..."
    
    users = User.all
    puts "Found #{users.length} users to send password reset emails to"
    
    users.each do |user|
      begin
        user.send_reset_password_instructions
        puts "✅ Password reset email sent to: #{user.email}"
      rescue => e
        puts "❌ Failed to send password reset email to #{user.email}: #{e.message}"
      end
    end
    
    puts "\n🎉 Password reset email campaign completed!"
    puts "Users should check their email and follow the reset instructions."
  end
end 