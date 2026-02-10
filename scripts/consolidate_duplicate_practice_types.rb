#!/usr/bin/env ruby
# Script to consolidate duplicate practice types (case-insensitive duplicates)
# Usage: rails runner scripts/consolidate_duplicate_practice_types.rb

puts "="*60
puts "CONSOLIDATING DUPLICATE PRACTICE TYPES"
puts "="*60
puts ""

# Find all practice types grouped by lowercase name
practice_types_by_lowercase = PracticeType.all.group_by { |pt| pt.name.downcase }

duplicates_found = false
consolidated_count = 0

practice_types_by_lowercase.each do |lowercase_name, practice_types|
  next if practice_types.length == 1
  
  duplicates_found = true
  puts "Found #{practice_types.length} practice type(s) with name '#{lowercase_name}':"
  
  # Determine which one to keep (prefer the one with proper capitalization)
  # Priority: 1) "ABA Therapy" over "Aba Therapy", 2) Most providers, 3) Oldest ID
  keep_practice_type = practice_types.max_by do |pt|
    [
      pt.name == 'ABA Therapy' ? 1 : 0,  # Prefer "ABA Therapy" capitalization
      pt.providers.count,                  # Prefer one with most providers
      -pt.id                               # Prefer oldest (lower ID)
    ]
  end
  
  duplicates = practice_types.reject { |pt| pt.id == keep_practice_type.id }
  
  puts "  ✅ KEEPING: ID #{keep_practice_type.id} - '#{keep_practice_type.name}' (#{keep_practice_type.providers.count} providers)"
  
  duplicates.each do |duplicate|
    provider_count = duplicate.providers.count
    location_count = duplicate.locations.count
    
    puts "  ❌ CONSOLIDATING: ID #{duplicate.id} - '#{duplicate.name}' (#{provider_count} providers, #{location_count} locations)"
    
    # Move all provider associations to the kept practice type
    duplicate.providers.each do |provider|
      unless provider.practice_types.include?(keep_practice_type)
        provider.practice_types << keep_practice_type
        puts "    → Moved provider #{provider.id} (#{provider.name})"
      end
      provider.practice_types.delete(duplicate)
    end
    
    # Move all location associations to the kept practice type
    duplicate.locations.each do |location|
      unless location.practice_types.include?(keep_practice_type)
        location.practice_types << keep_practice_type
        puts "    → Moved location #{location.id} (#{location.name})"
      end
      location.practice_types.delete(duplicate)
    end
    
    # Delete the duplicate
    duplicate.destroy
    puts "    ✅ Deleted duplicate practice type ID #{duplicate.id}"
    consolidated_count += 1
  end
  
  puts ""
end

if duplicates_found
  puts "="*60
  puts "CONSOLIDATION SUMMARY"
  puts "="*60
  puts "Practice types consolidated: #{consolidated_count}"
  puts ""
  puts "Remaining practice types:"
  PracticeType.order(:name).each do |pt|
    puts "  ID: #{pt.id}, Name: '#{pt.name}', Providers: #{pt.providers.count}, Locations: #{pt.locations.count}"
  end
else
  puts "✅ No duplicate practice types found. All practice types are unique (case-insensitive)."
end

puts ""
puts "Done!"

