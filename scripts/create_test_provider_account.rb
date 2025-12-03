#!/usr/bin/env ruby
# Script to create a test provider account for sponsorship testing
# Usage: rails runner scripts/create_test_provider_account.rb

email = 'provider61example@example.com'
password = 'testpassword123'
provider_name = 'Test Provider 61'

puts "🔧 Creating test provider account..."
puts "Email: #{email}"
puts "Password: #{password}"
puts ""

# Check if user already exists
existing_user = User.find_by(email: email)
if existing_user
  puts "⚠️  User already exists. Resetting password..."
  existing_user.password = password
  existing_user.password_confirmation = password
  existing_user.save!
  provider = existing_user.provider || Provider.find_by(email: email)
  if provider
    puts "✅ Password reset for existing user"
    puts "User ID: #{existing_user.id}"
    puts "Provider: #{provider.name} (ID: #{provider.id})"
    exit 0
  end
end

# Create user
user = User.new(
  email: email,
  password: password,
  password_confirmation: password,
  role: 'provider'
)

unless user.save
  puts "❌ Failed to create user:"
  puts user.errors.full_messages.join(", ")
  exit 1
end

puts "✅ User created: #{user.email} (ID: #{user.id})"

# Create provider
provider = Provider.new(
  name: provider_name,
  email: email,
  status: :approved,
  in_home_only: false,
  service_delivery: {
    'in_home' => true,
    'in_clinic' => true,
    'telehealth' => true
  },
  category: 'aba_therapy',
  user: user
)

unless provider.save
  puts "❌ Failed to create provider:"
  puts provider.errors.full_messages.join(", ")
  user.destroy
  exit 1
end

puts "✅ Provider created: #{provider.name} (ID: #{provider.id})"

# Initialize provider insurances
begin
  provider.initialize_provider_insurances
  puts "✅ Provider insurances initialized"
rescue => e
  puts "⚠️  Warning: Could not initialize insurances: #{e.message}"
end

puts ""
puts "🎉 Test account created successfully!"
puts ""
puts "Credentials:"
puts "  Email: #{email}"
puts "  Password: #{password}"
puts ""
puts "Account Details:"
puts "  User ID: #{user.id}"
puts "  Provider ID: #{provider.id}"
puts "  Provider Name: #{provider.name}"
puts "  Status: #{provider.status}"
puts ""
puts "You can now test:"
puts "  1. Login with these credentials"
puts "  2. Access provider dashboard"
puts "  3. Test sponsorship checkout: POST /api/v1/billing/checkout"
puts "  4. Test view stats (after becoming Community Sponsor)"
puts ""
