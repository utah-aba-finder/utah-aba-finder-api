# Seed file for provider categories and fields
# Run with: rails runner db/seeds_provider_categories.rb

puts "🌱 Seeding provider categories and fields..."

# Create provider categories
categories = [
  {
    name: "ABA Therapy",
    slug: "aba_therapy",
    description: "Applied Behavior Analysis therapy providers",
    display_order: 1,
    fields: [
      { name: "Specialties", field_type: "select", required: true, options: { choices: ["Autism", "ADHD", "Behavioral Issues", "Developmental Delays", "Social Skills"] } },
      { name: "Certifications", field_type: "select", required: true, options: { choices: ["BCBA", "BCaBA", "RBT", "Licensed Therapist"] } },
      { name: "Age Groups", field_type: "select", required: true, options: { choices: ["0-3", "3-5", "5-12", "12-18", "18+"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "Sliding Scale"] } },
      { name: "Emergency Services", field_type: "boolean", required: false, help_text: "Available for urgent behavioral needs" }
    ]
  },
  {
    name: "Dentists",
    slug: "dentists",
    description: "Dental care providers",
    display_order: 2,
    fields: [
      { name: "Specialties", field_type: "select", required: true, options: { choices: ["General Dentistry", "Pediatric Dentistry", "Orthodontics", "Endodontics", "Periodontics"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Delta Dental", "MetLife", "Aetna", "Cigna", "Self-Pay"] } },
      { name: "Emergency Services", field_type: "boolean", required: false, help_text: "Available for dental emergencies" },
      { name: "Sedation Options", field_type: "select", required: false, options: { choices: ["Nitrous Oxide", "Oral Sedation", "IV Sedation", "None"] } },
      { name: "Special Needs Accommodations", field_type: "boolean", required: false, help_text: "Experience with special needs patients" }
    ]
  },
  {
    name: "Therapists",
    slug: "therapists",
    description: "Mental health and counseling providers",
    display_order: 3,
    fields: [
      { name: "Licenses", field_type: "select", required: true, options: { choices: ["LCSW", "LMFT", "LPC", "Psychologist", "Psychiatrist"] } },
      { name: "Therapy Types", field_type: "select", required: true, options: { choices: ["CBT", "DBT", "Play Therapy", "Family Therapy", "Group Therapy", "Individual Therapy"] } },
      { name: "Specialties", field_type: "select", required: false, options: { choices: ["Anxiety", "Depression", "Trauma", "Autism", "ADHD", "Family Issues"] } },
      { name: "Sliding Scale", field_type: "boolean", required: false, help_text: "Offers sliding scale fees" },
      { name: "Teletherapy", field_type: "boolean", required: false, help_text: "Available for online sessions" }
    ]
  },
  {
    name: "Physical Therapists",
    slug: "physical_therapists",
    description: "Physical therapy and rehabilitation providers",
    display_order: 4,
    fields: [
      { name: "Specialties", field_type: "select", required: true, options: { choices: ["Pediatric PT", "Sports PT", "Neurological PT", "Orthopedic PT", "Geriatric PT"] } },
      { name: "Equipment Available", field_type: "select", required: false, options: { choices: ["Treadmill", "Exercise Bikes", "Resistance Bands", "Balance Equipment", "Aquatic Therapy"] } },
      { name: "Home Visits", field_type: "boolean", required: false, help_text: "Provides in-home physical therapy" },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Medicare", "Medicaid", "Private Insurance", "Self-Pay"] } },
      { name: "Special Needs Experience", field_type: "boolean", required: false, help_text: "Experience with special needs patients" }
    ]
  },
  {
    name: "Barbers/Hair",
    slug: "barbers_hair",
    description: "Hair care and styling providers",
    display_order: 5,
    fields: [
      { name: "Services", field_type: "select", required: true, options: { choices: ["Haircuts", "Hair Styling", "Hair Coloring", "Extensions", "Braiding", "Special Needs Haircuts"] } },
      { name: "Special Needs Experience", field_type: "boolean", required: false, help_text: "Experience with special needs clients" },
      { name: "Home Visits", field_type: "boolean", required: false, help_text: "Provides in-home services" },
      { name: "Appointment Only", field_type: "boolean", required: false, help_text: "Accepts walk-ins or appointment only" },
      { name: "Payment Methods", field_type: "select", required: false, options: { choices: ["Cash", "Credit Card", "Insurance", "Sliding Scale"] } }
    ]
  },
  {
    name: "Advocates",
    slug: "advocates",
    description: "Legal and disability rights advocates",
    display_order: 6,
    fields: [
      { name: "Specialties", field_type: "select", required: true, options: { choices: ["Autism Rights", "Disability Rights", "Education Rights", "Healthcare Rights", "Employment Rights"] } },
      { name: "Services", field_type: "select", required: true, options: { choices: ["Legal Representation", "Case Management", "Rights Education", "Mediation", "Appeals"] } },
      { name: "Geographic Coverage", field_type: "text", required: true, help_text: "Counties or regions served" },
      { name: "Fee Structure", field_type: "select", required: false, options: { choices: ["Free", "Sliding Scale", "Hourly Rate", "Flat Fee", "Pro Bono"] } },
      { name: "Languages", field_type: "select", required: false, options: { choices: ["English", "Spanish", "ASL", "Other"] } }
    ]
  }
]

categories.each do |category_data|
  fields_data = category_data.delete(:fields)
  
  category = ProviderCategory.find_or_create_by(slug: category_data[:slug]) do |c|
    c.assign_attributes(category_data)
  end
  
  puts "✅ Created/Updated category: #{category.name}"
  
  # Create fields for this category
  fields_data.each_with_index do |field_data, index|
    field = category.category_fields.find_or_create_by(name: field_data[:name]) do |f|
      f.assign_attributes(field_data.merge(display_order: index + 1))
    end
    
    puts "  📝 Field: #{field.name} (#{field.field_type})"
  end
end

puts "🎉 Provider categories seeding complete!"
puts "📊 Total categories: #{ProviderCategory.count}"
puts "📝 Total fields: #{CategoryField.count}" 