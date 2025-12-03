#!/usr/bin/env ruby
# Script to reset a user's password
# Usage: rails runner scripts/reset_user_password.rb <email> <new_password>

email = ARGV[0] || 'provider61example@example.com'
new_password = ARGV[1] || 'testpassword123'

user = User.find_by(email: email)

if user.nil?
  puts "❌ User not found with email: #{email}"
  puts "\nAvailable users:"
  User.limit(10).each do |u|
    puts "  - #{u.email}"
  end
  exit 1
end

user.password = new_password
user.password_confirmation = new_password

if user.save
  puts "✅ Password reset successfully!"
  puts "Email: #{user.email}"
  puts "New Password: #{new_password}"
  puts "User ID: #{user.id}"
  if user.provider
    puts "Provider: #{user.provider.name} (ID: #{user.provider.id})"
  end
else
  puts "❌ Failed to reset password:"
  puts user.errors.full_messages.join(", ")
  exit 1
end
