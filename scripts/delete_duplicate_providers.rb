#!/usr/bin/env ruby
# Script to safely delete duplicate providers
# Usage: rails runner scripts/delete_duplicate_providers.rb [provider_id_to_keep] [duplicate_id1] [duplicate_id2] ...

if ARGV.length < 2
  puts "Usage: rails runner scripts/delete_duplicate_providers.rb [keep_id] [duplicate_id1] [duplicate_id2] ..."
  puts "Example: rails runner scripts/delete_duplicate_providers.rb 1262 1261 1260 1259 1258 1257 1256 1255"
  exit 1
end

keep_id = ARGV[0].to_i
duplicate_ids = ARGV[1..-1].map(&:to_i)

puts "="*60
puts "DELETING DUPLICATE PROVIDERS"
puts "="*60
puts "Keeping Provider ID: #{keep_id}"
puts "Deleting Provider IDs: #{duplicate_ids.join(', ')}"
puts ""

# Verify the provider to keep exists
keep_provider = Provider.find_by(id: keep_id)
unless keep_provider
  puts "❌ ERROR: Provider ID #{keep_id} not found!"
  exit 1
end

puts "✅ Provider to keep:"
puts "   ID: #{keep_provider.id}"
puts "   Name: #{keep_provider.name}"
puts "   Email: #{keep_provider.email}"
puts ""

# Verify duplicates exist
duplicate_providers = Provider.where(id: duplicate_ids).to_a
missing_ids = duplicate_ids - duplicate_providers.map(&:id)

if missing_ids.any?
  puts "⚠️  WARNING: Some provider IDs not found: #{missing_ids.join(', ')}"
end

if duplicate_providers.empty?
  puts "❌ No duplicate providers found to delete"
  exit 1
end

puts "Found #{duplicate_providers.count} duplicate provider(s) to delete:"
duplicate_providers.each do |provider|
  puts "   - ID: #{provider.id}, Name: #{provider.name}, Created: #{provider.created_at}"
end

puts ""
print "Are you sure you want to delete these providers? (yes/no): "
confirmation = STDIN.gets.chomp.downcase

unless confirmation == 'yes'
  puts "❌ Deletion cancelled"
  exit 0
end

puts ""
puts "Deleting duplicates..."

deleted_count = 0
failed_count = 0

duplicate_providers.each do |provider|
  begin
    # Check if this provider is linked to the user
    user = User.find_by(provider_id: provider.id)
    if user
      puts "⚠️  Provider #{provider.id} is linked to user #{user.id}, unlinking first..."
      user.update_column(:provider_id, keep_id)
      puts "   ✅ Unlinked user #{user.id} from provider #{provider.id}, linked to #{keep_id}"
    end
    
    # Delete the provider (this will cascade delete associations)
    provider.destroy
    puts "✅ Deleted Provider ID #{provider.id}"
    deleted_count += 1
  rescue => e
    puts "❌ Failed to delete Provider ID #{provider.id}: #{e.message}"
    failed_count += 1
  end
end

puts ""
puts "="*60
puts "SUMMARY"
puts "="*60
puts "✅ Successfully deleted: #{deleted_count} provider(s)"
puts "❌ Failed to delete: #{failed_count} provider(s)" if failed_count > 0
puts ""
puts "✅ Provider ID #{keep_id} is now the only provider for this account"

