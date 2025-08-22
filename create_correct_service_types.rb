#!/usr/bin/env ruby

# Script to create the correct service types
# This runs in CI/test environments

require_relative 'config/environment'

puts "🔧 Creating Correct Service Types..."

# Remove any existing practice types
PracticeType.destroy_all

# Create the correct service types that match your Provider Registration system
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

puts "Creating #{services.count} service types..."

services.each_with_index do |name, index|
  pt = PracticeType.create!(name: name)
  puts "✅ #{index + 1}. #{pt.name} (ID: #{pt.id})"
end

puts "\n🎉 Service Types Created Successfully!"
puts "Total: #{PracticeType.count} service types"

puts "\n📋 Final Service Types List:"
PracticeType.order(:id).each { |pt| puts "  - #{pt.name}" }

puts "\n✅ Database is ready with correct service types!"
