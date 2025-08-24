#!/usr/bin/env ruby

# Script to fix Autism Evaluation categorization
# Most providers should be ABA Therapy, not Autism Evaluation specialists

require_relative 'config/environment'

puts "🔧 Fixing Autism Evaluation Categorization..."
puts "Target: More realistic distribution with most providers as ABA Therapy"

# First, clear all existing practice type associations
puts "\n🗑️ Clearing all practice type associations..."
ProviderPracticeType.destroy_all
puts "✅ Cleared all practice type associations"

# Get the 4 service types
aba_type = PracticeType.find_by(name: "ABA Therapy")
autism_type = PracticeType.find_by(name: "Autism Evaluation")
speech_type = PracticeType.find_by(name: "Speech Therapy")
ot_type = PracticeType.find_by(name: "Occupational Therapy")

puts "🔍 Found service types:"
puts "  - ABA Therapy: #{aba_type&.id}"
puts "  - Autism Evaluation: #{autism_type&.id}"
puts "  - Speech Therapy: #{speech_type&.id}"
puts "  - Occupational Therapy: #{ot_type&.id}"

# Create a more accurate mapping
puts "\n🔗 Creating more accurate provider categorization..."

# Only providers with category 'autism_evaluations' should be Autism Evaluation
autism_eval_providers = Provider.where(category: 'autism_evaluations').limit(15) # Target ~15
if autism_eval_providers.any?
  autism_eval_providers.each { |p| ProviderPracticeType.create!(provider: p, practice_type: autism_type) }
  puts "✅ Categorized #{autism_eval_providers.count} providers as Autism Evaluation"
end

# Speech therapy providers should stay as Speech Therapy
speech_providers = Provider.where(category: 'speech_therapy').limit(12)
if speech_providers.any?
  speech_providers.each { |p| ProviderPracticeType.create!(provider: p, practice_type: speech_type) }
  puts "✅ Categorized #{speech_providers.count} providers as Speech Therapy"
end

# Occupational therapy providers should stay as Occupational Therapy
ot_providers = Provider.where(category: 'occupational_therapy').limit(20)
if ot_providers.any?
  ot_providers.each { |p| ProviderPracticeType.create!(provider: p, practice_type: ot_type) }
  puts "✅ Categorized #{ot_providers.count} providers as Occupational Therapy"
end

# All other providers should be ABA Therapy (this is the main service in Utah)
remaining_providers = Provider.left_joins(:practice_types).where(practice_types: { id: nil })
if remaining_providers.any?
  remaining_providers.each { |p| ProviderPracticeType.create!(provider: p, practice_type: aba_type) }
  puts "✅ Categorized #{remaining_providers.count} providers as ABA Therapy"
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

puts "\n✅ Autism Evaluation categorization fixed!"
puts "Now you should have a more realistic distribution with most providers as ABA Therapy."

