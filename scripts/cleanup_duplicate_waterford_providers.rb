#!/usr/bin/env ruby
# Script to clean up duplicate Waterford.org providers
# Usage: rails runner scripts/cleanup_duplicate_waterford_providers.rb

email = 'tiasmith@waterford.org'
puts "🧹 Cleaning up duplicate providers for #{email}..."

# Find all providers with this email
providers = Provider.where(email: email).order(:id)
puts "Found #{providers.count} providers"

if providers.count <= 1
  puts "✅ No duplicates found. Nothing to clean up."
  exit 0
end

# Keep the first one (lowest ID)
keep_provider = providers.first
duplicates = providers[1..-1]

puts "✅ Keeping provider ID: #{keep_provider.id} (created: #{keep_provider.created_at})"
puts "🗑️  Deleting #{duplicates.count} duplicate providers..."

# Update user to point to the kept provider
user = User.find_by(email: email)
if user && user.provider_id != keep_provider.id
  puts "📝 Updating user #{user.id} to point to provider #{keep_provider.id}"
  user.update!(provider_id: keep_provider.id)
end

# Delete duplicate providers (this will cascade delete related records)
duplicates.each do |provider|
  puts "  Deleting provider #{provider.id}..."
  provider.destroy!
end

puts "✅ Cleanup complete! Kept provider ID: #{keep_provider.id}"
puts "📊 Final count: #{Provider.where(email: email).count} provider(s)"

