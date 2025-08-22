#!/usr/bin/env ruby

# Simple script to fix service types
# Run this with: ruby fix_service_types.rb

require 'bundler/setup'
require_relative 'config/environment'

puts "🔧 Fixing Service Types to Match Provider Registration..."

# Remove all existing practice types
puts "Removing existing practice types..."
PracticeType.destroy_all

# Create the correct service types that match your Provider Registration system
puts "Creating correct service types..."
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

services.each do |name|
  pt = PracticeType.create!(name: name)
  puts "✅ Created: #{pt.name} (ID: #{pt.id})"
end

puts "\n🎉 Service Types Fixed!"
puts "Total PracticeType services: #{PracticeType.count}"
puts "\nFinal Service Types:"
PracticeType.order(:id).each { |pt| puts "  - #{pt.name}" }

puts "\n✅ Your frontend should now show the correct service types!"
