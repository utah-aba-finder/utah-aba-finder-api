#!/usr/bin/env ruby

# Script to restore the original 4 service types
# This goes back to what you had before we added the missing 8 types

require_relative 'config/environment'

puts "🔧 Restoring Original 4 Service Types..."
puts "Target: 4 original service types (ABA Therapy, Autism Evaluation, Speech Therapy, Occupational Therapy)"

# First, clear all existing practice type associations
puts "\n🗑️ Clearing all practice type associations..."
ProviderPracticeType.destroy_all
puts "✅ Cleared all practice type associations"

# Clear all practice types
puts "\n🗑️ Clearing all practice types..."
PracticeType.destroy_all
puts "✅ Cleared all practice types"

# Create only the original 4 service types
puts "\n🔗 Creating original 4 service types..."
aba_type = PracticeType.create!(name: "ABA Therapy")
autism_type = PracticeType.create!(name: "Autism Evaluation")
speech_type = PracticeType.create!(name: "Speech Therapy")
ot_type = PracticeType.create!(name: "Occupational Therapy")
puts "✅ Created: ABA Therapy (ID: #{aba_type.id})"
puts "✅ Created: Autism Evaluation (ID: #{autism_type.id})"
puts "✅ Created: Speech Therapy (ID: #{speech_type.id})"
puts "✅ Created: Occupational Therapy (ID: #{ot_type.id})"

# Now categorize providers into these 4 types based on their original category
puts "\n🔗 Categorizing providers into 4 service types..."

# Map the original categories to the 4 service types
category_mapping = {
  'aba_therapy' => 'ABA Therapy',
  'autism_evaluations' => 'Autism Evaluation',
  'speech_therapy' => 'Speech Therapy',
  'occupational_therapy' => 'Occupational Therapy',
  # Map other categories to the closest of the 4 types
  'psychology' => 'Autism Evaluation',
  'pediatricians' => 'Autism Evaluation',
  'dentists' => 'Autism Evaluation',
  'physical_therapists' => 'Occupational Therapy',
  'coaches_mentors' => 'ABA Therapy',
  'advocates' => 'ABA Therapy',
  'other' => 'ABA Therapy'
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

puts "\n✅ Original 4 service types restored! This is what you had before we added the missing 8 types."

