#!/usr/bin/env ruby
# Script to add "Educational Programs" category for learning program providers
# Usage: rails runner scripts/add_educational_programs_category.rb

puts "🎓 Adding Educational Programs category..."

category_data = {
  name: "Educational Programs",
  slug: "educational_programs",
  description: "Online and in-person learning programs for early childhood education, often integrated with ABA therapy or early education settings",
  display_order: 13,
  is_active: true
}

# Create or update the category
category = ProviderCategory.find_or_create_by(slug: category_data[:slug]) do |c|
  c.assign_attributes(category_data)
end

if category.persisted?
  category.update!(category_data)
  puts "✅ Updated category: #{category.name}"
else
  category.save!
  puts "✅ Created category: #{category.name}"
end

# Define fields for this category
fields_data = [
  {
    name: "Program Types",
    field_type: "multi_select",
    required: true,
    options: {
      choices: [
        "Early Learning Programs",
        "PreK-2 Curriculum",
        "Reading Programs",
        "Math Programs",
        "Social Skills Programs",
        "Language Development",
        "Cognitive Development",
        "ABA-Integrated Programs",
        "Early Education Support",
        "Homeschool Support",
        "Supplemental Learning",
        "Online Learning Platforms"
      ]
    },
    help_text: "Types of educational programs offered"
  },
  {
    name: "Credentials/Qualifications",
    field_type: "multi_select",
    required: true,
    options: {
      choices: [
        "Licensed Teacher",
        "Certified Educator",
        "Early Childhood Specialist",
        "Special Education Teacher",
        "BCBA/ABA Specialist",
        "Curriculum Developer",
        "Educational Therapist",
        "Learning Specialist",
        "Non-Profit Organization",
        "Accredited Program"
      ]
    },
    help_text: "Qualifications and credentials of program providers"
  },
  {
    name: "Age Groups",
    field_type: "multi_select",
    required: true,
    options: {
      choices: [
        "0-3 (Early Intervention)",
        "3-5 (PreK)",
        "5-7 (Kindergarten-2nd Grade)",
        "3-8 (PreK-2nd Grade)",
        "All Ages"
      ]
    },
    help_text: "Age ranges served by the program"
  },
  {
    name: "Delivery Format",
    field_type: "multi_select",
    required: true,
    options: {
      choices: [
        "Online Only",
        "In-Person",
        "Hybrid (Online + In-Person)",
        "Self-Paced Online",
        "Live Online Sessions",
        "Recorded Content",
        "Interactive Platform"
      ]
    },
    help_text: "How the program is delivered"
  },
  {
    name: "Integration Options",
    field_type: "multi_select",
    required: false,
    options: {
      choices: [
        "ABA Therapy Integration",
        "Early Education Integration",
        "School Integration",
        "Homeschool Integration",
        "Therapy Integration",
        "Standalone Program"
      ]
    },
    help_text: "How the program can be integrated with other services"
  },
  {
    name: "Pricing",
    field_type: "multi_select",
    required: false,
    options: {
      choices: [
        "Free",
        "Sliding Scale",
        "Subscription-Based",
        "One-Time Fee",
        "Grant-Funded",
        "Non-Profit Pricing",
        "Flexible pricing based on your circumstances",
        "School District Contracts"
      ]
    },
    help_text: "Pricing options available"
  },
  {
    name: "Parent/Caregiver Support",
    field_type: "boolean",
    required: false,
    help_text: "Includes training or support for parents/caregivers"
  }
]

# Create fields for this category
fields_data.each_with_index do |field_data, index|
  field_slug = field_data[:name].downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
  
  options_data = field_data[:options]
  field_options = options_data[:choices] if options_data && options_data[:choices]
  
  field = category.category_fields.find_or_create_by(name: field_data[:name]) do |f|
    f.assign_attributes(
      field_type: field_data[:field_type],
      required: field_data[:required] || false,
      options: field_options || {},
      display_order: index + 1,
      help_text: field_data[:help_text],
      slug: field_slug
    )
  end
  
  # Update existing fields
  if field.persisted?
    field.update!(
      field_type: field_data[:field_type],
      required: field_data[:required] || false,
      options: field_options || {},
      display_order: index + 1,
      help_text: field_data[:help_text],
      slug: field_slug
    )
  end
  
  puts "  📝 Field: #{field.name} (#{field.field_type})"
end

puts ""
puts "🎉 Educational Programs category created successfully!"
puts "📊 Category: #{category.name} (#{category.slug})"
puts "📝 Total fields: #{category.category_fields.count}"

