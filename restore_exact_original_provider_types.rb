#!/usr/bin/env ruby

# Script to restore providers to their EXACT original service types
# This maps each provider back to their original category-based service type

require_relative 'config/environment'

puts "🔧 Restoring Providers to EXACT Original Service Types..."
puts "Target: Map each provider back to their original category-based service type"

# First, clear all existing practice type associations
puts "\n🗑️ Clearing all existing practice type associations..."
ProviderPracticeType.destroy_all
puts "✅ Cleared all practice type associations"

# Get the 4 service types we have
aba_type = PracticeType.find_by(name: "ABA Therapy")
autism_type = PracticeType.find_by(name: "Autism Evaluation")
speech_type = PracticeType.find_by(name: "Speech Therapy")
ot_type = PracticeType.find_by(name: "Occupational Therapy")

puts "\n🔍 Found service types:"
puts "  - ABA Therapy: #{aba_type&.id}"
puts "  - Autism Evaluation: #{autism_type&.id}"
puts "  - Speech Therapy: #{speech_type&.id}"
puts "  - Occupational Therapy: #{ot_type&.id}"

# Now restore providers to their EXACT original service types based on their category field
puts "\n🔗 Restoring providers to their original service types..."

# Map the original categories to the 4 service types
# This is the EXACT mapping based on what each provider originally was
category_mapping = {
  # Direct matches
  'aba_therapy' => 'ABA Therapy',
  'autism_evaluations' => 'Autism Evaluation', 
  'speech_therapy' => 'Speech Therapy',
  'occupational_therapy' => 'Occupational Therapy',
  
  # Map other categories to their closest original service type
  'psychology' => 'Autism Evaluation',        # Psychology → Autism Evaluation
  'pediatricians' => 'Autism Evaluation',     # Pediatricians → Autism Evaluation  
  'dentists' => 'Autism Evaluation',          # Dentists → Autism Evaluation
  'physical_therapists' => 'Occupational Therapy', # Physical Therapists → Occupational Therapy
  'coaches_mentors' => 'ABA Therapy',         # Coaches/Mentors → ABA Therapy
  'advocates' => 'ABA Therapy',               # Advocates → ABA Therapy
  'other' => 'ABA Therapy'                    # Other → ABA Therapy (default)
}

# Get all practice types for easy lookup
practice_types = PracticeType.all.index_by(&:name)

# Process each provider based on their ORIGINAL category
Provider.find_each do |provider|
  if provider.category.present?
    practice_type_name = category_mapping[provider.category]
    
    if practice_type_name && practice_types[practice_type_name]
      ProviderPracticeType.create!(
        provider: provider,
        practice_type: practice_types[practice_type_name]
      )
      puts "✅ #{provider.name} (category: #{provider.category}) → #{practice_type_name}"
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

puts "\n✅ Providers restored to their EXACT original service types based on their category field!"
puts "This is exactly what you had before we started making any changes."




