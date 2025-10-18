#!/usr/bin/env ruby

# Script to restore the original 12 service types
# This restores the state from before we started making changes

require_relative 'config/environment'

puts "🔧 Restoring Original 12 Service Types..."
puts "Target: 12 service types matching Provider Registration system"

# First, clear all existing practice type associations
puts "\n🗑️ Clearing all practice type associations..."
ProviderPracticeType.destroy_all
puts "✅ Cleared all practice type associations"

# Clear all practice types
puts "\n🗑️ Clearing all practice types..."
PracticeType.destroy_all
puts "✅ Cleared all practice types"

# Create the original 12 service types that match your Provider Registration system
puts "\n🔗 Creating original 12 service types..."
services = [
  'ABA Therapy',
  'Occupational Therapy', 
  'Autism Evaluations',
  'Dentists',
  'Pediatricians',
  'Orthodontists',
  'Coaches/Mentors',
  'Advocates',
  'Speech Therapy',
  'Barbers/Hairstylist',
  'Physical Therapists',
  'Therapists'
]

services.each_with_index do |name, index|
  pt = PracticeType.create!(name: name)
  puts "✅ #{index + 1}. #{pt.name} (ID: #{pt.id})"
end

# Now restore providers based on their original category field
puts "\n🔗 Restoring providers to their original categories..."

# Map category slugs to practice type names
category_mapping = {
  'aba_therapy' => 'ABA Therapy',
  'occupational_therapy' => 'Occupational Therapy',
  'autism_evaluations' => 'Autism Evaluations',
  'dentists' => 'Dentists',
  'pediatricians' => 'Pediatricians',
  'orthodontists' => 'Orthodontists',
  'coaches_mentors' => 'Coaches/Mentors',
  'advocates' => 'Advocates',
  'speech_therapy' => 'Speech Therapy',
  'barbers_hairstylist' => 'Barbers/Hairstylist',
  'physical_therapists' => 'Physical Therapists',
  'therapists' => 'Therapists',
  'psychology' => 'Autism Evaluations', # Map psychology to autism evaluations
  'other' => 'ABA Therapy' # Map "other" to ABA Therapy as default
}

# Get all practice types for easy lookup
practice_types = PracticeType.all.index_by(&:name)

# Process each provider based on their category
Provider.find_each do |provider|
  if provider.category.present?
    practice_type_name = category_mapping[provider.category]
    
    if practice_type_name && practice_types[practice_type_name]
      ProviderPracticeType.create!(
        provider: provider,
        practice_type: practice_types[practice_type_name]
      )
      puts "✅ #{provider.name} → #{practice_type_name}"
    else
      puts "⚠️  #{provider.name} (category: #{provider.category}) - no mapping found"
    end
  else
    puts "⚠️  #{provider.name} - no category"
  end
end

# Final verification
puts "\n🎉 Final Results:"
puts "Total providers: #{Provider.count}"
puts "Total practice types: #{PracticeType.count}"

puts "\n📋 Service Type Distribution:"
PracticeType.order(:id).each do |pt|
  count = Provider.joins(:practice_types).where(practice_types: { id: pt.id }).count
  puts "  - #{pt.name}: #{count} providers"
end

puts "\nProviders in Utah with ABA Therapy: #{Provider.joins(counties: :state).joins(:practice_types).where(counties: { state_id: 1 }).where(practice_types: { name: 'ABA Therapy' }).distinct.count}"

puts "\n✅ Original 12 service types restored! This matches your Provider Registration system exactly."




