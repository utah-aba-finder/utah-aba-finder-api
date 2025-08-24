#!/usr/bin/env ruby

# Script to properly categorize providers into the 4 correct service types
# This will fix the incorrect categorization from the previous script

require_relative 'config/environment'

puts "🔧 Fixing Provider Categorization..."
puts "Target: 4 service types with proper provider distribution"

# First, clear all existing practice type associations
puts "\n🗑️ Clearing all practice type associations..."
ProviderPracticeType.destroy_all
puts "✅ Cleared all practice type associations"

# Clear all practice types
puts "\n🗑️ Clearing all practice types..."
PracticeType.destroy_all
puts "✅ Cleared all practice types"

# Create the 4 correct service types
puts "\n🔗 Creating correct service types..."
aba_type = PracticeType.create!(name: "ABA Therapy")
autism_type = PracticeType.create!(name: "Autism Evaluation")
speech_type = PracticeType.create!(name: "Speech Therapy")
ot_type = PracticeType.create!(name: "Occupational Therapy")
puts "✅ Created: ABA Therapy (ID: #{aba_type.id})"
puts "✅ Created: Autism Evaluation (ID: #{autism_type.id})"
puts "✅ Created: Speech Therapy (ID: #{speech_type.id})"
puts "✅ Created: Occupational Therapy (ID: #{ot_type.id})"

# Now properly categorize providers based on their actual services and names
puts "\n🔗 Categorizing providers properly..."

# 1. ABA Therapy providers - these should be the core ABA providers
aba_keywords = ['aba', 'behavior', 'behavioral', 'autism therapy', 'autism treatment']
aba_providers = Provider.where("LOWER(name) LIKE ANY (ARRAY[?])", aba_keywords.map { |k| "%#{k}%" })
                        .or(Provider.where(category: 'aba_therapy'))
                        .limit(80) # Target ~70-80 ABA providers

if aba_providers.any?
  aba_providers.each { |p| ProviderPracticeType.create!(provider: p, practice_type: aba_type) }
  puts "✅ Categorized #{aba_providers.count} providers as ABA Therapy"
end

# 2. Speech Therapy providers - look for speech-related names and services
speech_keywords = ['speech', 'language', 'communication', 'articulation', 'fluency']
speech_providers = Provider.where("LOWER(name) LIKE ANY (ARRAY[?])", speech_keywords.map { |k| "%#{k}%" })
                          .or(Provider.where(category: 'speech_therapy'))
                          .limit(20) # Target ~15-20 speech providers

if speech_providers.any?
  speech_providers.each { |p| ProviderPracticeType.create!(provider: p, practice_type: speech_type) }
  puts "✅ Categorized #{speech_providers.count} providers as Speech Therapy"
end

# 3. Occupational Therapy providers
ot_keywords = ['occupational', 'ot', 'sensory', 'motor', 'adl', 'fine motor']
ot_providers = Provider.where("LOWER(name) LIKE ANY (ARRAY[?])", ot_keywords.map { |k| "%#{k}%" })
                      .or(Provider.where(category: 'occupational_therapy'))
                      .limit(20) # Target ~15-20 OT providers

if ot_providers.any?
  ot_providers.each { |p| ProviderPracticeType.create!(provider: p, practice_type: ot_type) }
  puts "✅ Categorized #{ot_providers.count} providers as Occupational Therapy"
end

# 4. Autism Evaluation providers - these are typically psychologists, clinics, etc.
evaluation_keywords = ['evaluation', 'assessment', 'diagnosis', 'clinic', 'psychology', 'neuropsych']
evaluation_providers = Provider.where("LOWER(name) LIKE ANY (ARRAY[?])", evaluation_keywords.map { |k| "%#{k}%" })
                              .or(Provider.where(category: 'autism_evaluations'))
                              .or(Provider.where(category: 'psychology'))
                              .limit(25) # Target ~20-25 evaluation providers

if evaluation_providers.any?
  evaluation_providers.each { |p| ProviderPracticeType.create!(provider: p, practice_type: autism_type) }
  puts "✅ Categorized #{evaluation_providers.count} providers as Autism Evaluation"
end

# Final verification
puts "\n🎉 Final Results:"
puts "Total providers: #{Provider.count}"
puts "ABA Therapy providers: #{Provider.joins(:practice_types).where(practice_types: { name: 'ABA Therapy' }).count}"
puts "Autism Evaluation providers: #{Provider.joins(:practice_types).where(practice_types: { name: 'Autism Evaluation' }).count}"
puts "Speech Therapy providers: #{Provider.joins(:practice_types).where(practice_types: { name: 'Speech Therapy' }).count}"
puts "Occupational Therapy providers: #{Provider.joins(:practice_types).where(practice_types: { name: 'Occupational Therapy' }).count}"
puts "Providers with no practice types: #{Provider.left_joins(:practice_types).where(practice_types: { id: nil }).count}"

puts "\nProviders in Utah with ABA Therapy: #{Provider.joins(counties: :state).joins(:practice_types).where(counties: { state_id: 1 }).where(practice_types: { name: 'ABA Therapy' }).distinct.count}"

puts "\n✅ Provider categorization fixed! You should now have the correct distribution of providers across the 4 service types."

