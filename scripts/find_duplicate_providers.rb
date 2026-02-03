#!/usr/bin/env ruby
# Script to find duplicate providers and identify which one to keep
# Usage: rails runner scripts/find_duplicate_providers.rb [provider_name_or_email]

provider_name_or_email = ARGV[0]

if provider_name_or_email.nil?
  puts "Usage: rails runner scripts/find_duplicate_providers.rb [provider_name_or_email]"
  puts "Example: rails runner scripts/find_duplicate_providers.rb SJchildsLLC"
  puts "Example: rails runner scripts/find_duplicate_providers.rb provider@example.com"
  exit 1
end

# Find providers by name or email
providers = if provider_name_or_email.include?('@')
  Provider.where('email ILIKE ?', "%#{provider_name_or_email}%").order(created_at: :desc)
else
  Provider.where('name ILIKE ?', "%#{provider_name_or_email}%").order(created_at: :desc)
end

if providers.empty?
  puts "❌ No providers found matching: #{provider_name_or_email}"
  exit 1
end

puts "Found #{providers.count} provider(s) matching '#{provider_name_or_email}':\n\n"

providers.each_with_index do |provider, index|
  puts "Provider #{index + 1}:"
  puts "  ID: #{provider.id}"
  puts "  Name: #{provider.name}"
  puts "  Email: #{provider.email}"
  puts "  Created At: #{provider.created_at}"
  puts "  Updated At: #{provider.updated_at}"
  puts "  Status: #{provider.status}"
  puts "  Locations Count: #{provider.locations.count}"
  puts "  Counties Count: #{provider.counties.count}"
  puts "  Practice Types Count: #{provider.practice_types.count}"
  
  # Check if linked to user
  user = User.find_by(email: provider.email) || User.find_by(provider_id: provider.id)
  if user
    puts "  ✅ Linked to User ID: #{user.id} (#{user.email})"
    puts "     User Provider ID: #{user.provider_id}"
  else
    puts "  ⚠️  Not linked to any user"
  end
  
  # Check if there's an approved registration
  registration = ProviderRegistration.where(
    'provider_name ILIKE ? OR email = ?',
    "%#{provider.name}%",
    provider.email
  ).where(status: 'approved', is_processed: true).order(updated_at: :desc).first
  
  if registration
    puts "  ✅ Has approved registration (ID: #{registration.id}, Approved: #{registration.reviewed_at})"
  end
  
  puts ""
end

# Determine which one to keep
puts "\n" + "="*60
puts "RECOMMENDATION:"
puts "="*60

# Find the most recently created one that's linked to a user
linked_provider = providers.find { |p| User.exists?(provider_id: p.id) || User.exists?(email: p.email, provider_id: p.id) }

if linked_provider
  puts "✅ KEEP: Provider ID #{linked_provider.id}"
  puts "   Reason: Linked to user account"
  puts "   Name: #{linked_provider.name}"
  puts "   Email: #{linked_provider.email}"
  puts ""
  puts "❌ DELETE: The other #{providers.count - 1} provider(s)"
  providers.reject { |p| p.id == linked_provider.id }.each do |p|
    puts "   - Provider ID #{p.id} (#{p.name})"
  end
else
  # If none are linked, keep the most recent one
  most_recent = providers.first
  puts "✅ KEEP: Provider ID #{most_recent.id} (most recent)"
  puts "   Name: #{most_recent.name}"
  puts "   Email: #{most_recent.email}"
  puts "   Created: #{most_recent.created_at}"
  puts ""
  puts "❌ DELETE: The other #{providers.count - 1} provider(s)"
  providers.reject { |p| p.id == most_recent.id }.each do |p|
    puts "   - Provider ID #{p.id} (#{p.name}, created: #{p.created_at})"
  end
end

puts "\n" + "="*60
puts "To delete duplicates, run:"
providers.reject { |p| p.id == (linked_provider || providers.first).id }.each do |p|
  puts "  Provider.find(#{p.id}).destroy"
end

