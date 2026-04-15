#!/usr/bin/env ruby
# Script to resend approval email for a provider registration
# Usage: rails runner scripts/resend_approval_email.rb [provider_name_or_id]

provider_name_or_id = ARGV[0]

if provider_name_or_id.nil?
  puts "Usage: rails runner scripts/resend_approval_email.rb [provider_name_or_id]"
  puts "Example: rails runner scripts/resend_approval_email.rb SJchildsLLC"
  puts "Example: rails runner scripts/resend_approval_email.rb 123"
  exit 1
end

# Find the provider
provider = if provider_name_or_id.match?(/^\d+$/)
  Provider.find_by(id: provider_name_or_id.to_i)
else
  Provider.where('name ILIKE ?', "%#{provider_name_or_id}%").first
end

unless provider
  puts "❌ Provider not found: #{provider_name_or_id}"
  exit 1
end

puts "✅ Found provider: #{provider.name} (ID: #{provider.id})"
puts "   Email: #{provider.email}"

# Find the registration
registration = ProviderRegistration.where(
  'provider_name ILIKE ? OR email = ? OR applicant_email = ?',
  "%#{provider.name}%",
  provider.email,
  provider.email
).order(created_at: :desc).first

unless registration
  puts "❌ Registration not found for provider"
  exit 1
end

puts "✅ Found registration: #{registration.provider_name} (ID: #{registration.id})"
puts "   Status: #{registration.status}"
puts "   Is Processed: #{registration.is_processed}"

unless registration.status == 'approved' && registration.is_processed
  puts "❌ Registration is not approved or not processed"
  exit 1
end

# Find the user (login email is correspondence / applicant when set)
user = User.find_by(email: registration.correspondence_email)

unless user
  puts "❌ User not found for email: #{registration.correspondence_email}"
  exit 1
end

puts "✅ Found user: #{user.email} (ID: #{user.id})"

# Check if user is linked to provider
unless user.provider_id == provider.id
  puts "⚠️  User is not linked to this provider. Linking now..."
  user.update!(provider_id: provider.id)
end

# Generate a new password for the email (since we don't have the original)
new_password = SecureRandom.alphanumeric(12)
user.instance_variable_set(:@plain_password, new_password)

puts "\n📧 Sending approval email..."
begin
  ProviderRegistrationMailer.approved_with_credentials(registration, user).deliver_now
  puts "✅ Approval email sent successfully!"
  puts "   New password: #{new_password}"
  puts "   Email sent to: #{registration.correspondence_email}"
rescue => e
  puts "❌ Failed to send email: #{e.message}"
  puts "   Backtrace: #{e.backtrace.first(5).join("\n   ")}"
  exit 1
end

