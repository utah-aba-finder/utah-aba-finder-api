#!/usr/bin/env ruby
# Backfill providers 1263 and 1264 from their approved registrations.
#
# This script is safe to run once; it will:
# - Recompute provider core attributes from registration.submitted_data
# - Rebuild practice types, insurance, counties, default location, and provider_attributes
# - NOT create any new providers
#
# Usage (from project root):
#   heroku run rails runner scripts/backfill_providers_from_registrations.rb --app utah-aba-finder-api
#

puts "=== Backfilling providers from registrations ==="

mapping = {
  233 => 1263, # registration_id => provider_id
  232 => 1264
}

mapping.each do |registration_id, provider_id|
  puts "\n----------------------------------------"
  puts "Processing Registration #{registration_id} -> Provider #{provider_id}"

  reg = ProviderRegistration.find_by(id: registration_id)
  if reg.nil?
    puts "❌ Registration #{registration_id} not found, skipping"
    next
  end

  provider = Provider.find_by(id: provider_id)
  if provider.nil?
    puts "❌ Provider #{provider_id} not found, skipping"
    next
  end

  puts "✅ Found registration #{reg.id} for #{reg.provider_name} (#{reg.email})"
  puts "✅ Found provider   #{provider.id} #{provider.name} (#{provider.email})"

  # Use the same data flattening logic as approval (now fixed to handle aba-therapy/aba_therapy)
  data = reg.send(:get_submitted_data)
  puts "🔍 Flattened submitted_data keys: #{data.keys.sort.inspect}"

  # Rebuild core provider attributes (mirrors create_provider_from_registration)
  provider_attributes = {
    name: reg.provider_name,
    email: reg.email,
    category: reg.category,
    status: :approved,

    # Basic business info - check both top level and nested category level
    website: data['website'] || '',
    phone: data['contact_phone'] || data['phone'] || '',

    # Service delivery options
    service_delivery: reg.send(:determine_service_delivery),

    # Service availability
    at_home_services: reg.send(:determine_at_home_services),
    in_clinic_services: reg.send(:determine_in_clinic_services),
    telehealth_services: reg.send(:determine_telehealth_services),

    # Accessibility and details
    spanish_speakers: data['spanish_speakers'] || 'Unknown',

    # Business details
    cost: data['pricing'] || data['cost'] || 'Contact us',
    waitlist: data['waitlist_status'] || data['waitlist'] || 'Contact us',
    min_age: reg.send(:extract_min_age, data),
    max_age: reg.send(:extract_max_age, data),

    # Default values for required fields
    in_home_only: true # Set to true to avoid location requirement
  }

  puts "🔧 Updating provider #{provider.id} core attributes..."
  provider.update!(provider_attributes)

  # Clear out existing associations that are derived from registration
  puts "🔧 Clearing derived associations (locations, counties, practice_types, provider_attributes)..."
  provider.locations.destroy_all
  provider.counties.clear
  provider.practice_types.clear
  provider.provider_attributes.destroy_all

  # Rebuild associations using the same private helpers
  puts "🔧 Setting up practice types..."
  reg.send(:setup_practice_types, provider)

  puts "🔧 Setting up insurance..."
  reg.send(:setup_insurance, provider)

  puts "🔧 Setting up counties served..."
  reg.send(:setup_counties_served, provider)

  puts "🔧 Creating default location..."
  reg.send(:create_default_location, provider)

  puts "🔧 Creating provider attributes (category-specific fields)..."
  reg.send(:create_provider_attributes, provider)

  provider.reload

  puts "✅ Finished backfill for Provider #{provider.id}:"
  puts "   Name: #{provider.name}"
  puts "   Email: #{provider.email}"
  puts "   Phone: #{provider.phone}"
  puts "   Website: #{provider.website}"
  puts "   Cost: #{provider.cost}"
  puts "   Waitlist: #{provider.waitlist}"
  puts "   Service delivery: #{provider.service_delivery.inspect}"
  puts "   Locations: #{provider.locations.map { |l| { id: l.id, city: l.city, state: l.state, phone: l.phone } }}"
  puts "   Practice types: #{provider.practice_types.pluck(:name).inspect}"
  puts "   Counties: #{provider.counties.pluck(:name).inspect}"
  puts "   Provider attributes count: #{provider.provider_attributes.count}"
end

puts "\n=== Backfill complete ==="


