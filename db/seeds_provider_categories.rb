
# Seeds for Provider Categories and Fields
puts "🌱 Seeding provider categories and fields..."

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
    name: "Autism Evaluations",
    slug: "autism_evaluations",
    description: "Professional autism assessment and diagnostic services",
    display_order: 2,
    fields: [
      { name: "Evaluation Types", field_type: "multi_select", required: true, options: { choices: ["ADOS-2", "ADI-R", "CARS-2", "GARS-3", "M-CHAT", "Comprehensive Assessment"] } },
      { name: "Credentials", field_type: "select", required: true, options: { choices: ["Licensed Psychologist", "Developmental Pediatrician", "Child Psychiatrist", "Licensed Clinical Social Worker", "Board Certified Behavior Analyst"] } },
      { name: "Age Range Served", field_type: "select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "Sliding Scale", "School District Contracts"] } },
      { name: "Report Turnaround", field_type: "select", required: false, options: { choices: ["1-2 weeks", "2-4 weeks", "4-6 weeks", "6+ weeks"] } }
    ]
  },
  {
    name: "Speech Therapy",
    slug: "speech_therapy",
    description: "Speech and language therapy services",
    display_order: 3,
    fields: [
      { name: "Speech Disorders", field_type: "multi_select", required: true, options: { choices: ["Articulation", "Language Delay", "Stuttering", "Voice Disorders", "Swallowing", "Social Communication"] } },
      { name: "Certifications", field_type: "select", required: true, options: { choices: ["SLP", "SLPA", "CCC-SLP", "Licensed Speech Therapist"] } },
      { name: "Age Groups", field_type: "select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "School District Contracts"] } },
      { name: "Teletherapy Available", field_type: "boolean", required: false, help_text: "Virtual therapy sessions available" }

    ]
  },
  {
    name: "Occupational Therapy",
    slug: "occupational_therapy",
    description: "Occupational therapy for developmental and sensory needs",
    display_order: 4,
    fields: [
      { name: "Focus Areas", field_type: "multi_select", required: true, options: { choices: ["Sensory Processing", "Fine Motor Skills", "Gross Motor Skills", "ADL Training", "Handwriting", "Visual Motor"] } },
      { name: "Certifications", field_type: "select", required: true, options: { choices: ["OT", "OTA", "Licensed Occupational Therapist"] } },
      { name: "Age Groups", field_type: "select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "School District Contracts"] } },
      { name: "Sensory Integration", field_type: "boolean", required: false, help_text: "Specialized sensory integration therapy" }
    ]
  },
  {
    name: "Coaching/Mentoring",
    slug: "coaching_mentoring",
    description: "Life skills coaching and mentoring services",
    display_order: 5,
    fields: [
      { name: "Coaching Areas", field_type: "multi_select", required: true, options: { choices: ["Life Skills", "Social Skills", "Executive Functioning", "Career Development", "Independent Living", "Relationship Skills"] } },
      { name: "Credentials", field_type: "select", required: true, options: { choices: ["Certified Coach", "Licensed Counselor", "Social Worker", "Life Coach", "Mentor"] } },
      { name: "Age Groups", field_type: "select", required: true, options: { choices: ["12-18 (Teen)", "18-25 (Young Adult)", "25+ (Adult)", "All Ages"] } },
      { name: "Session Format", field_type: "select", required: false, options: { choices: ["Individual", "Group", "Family", "Virtual", "In-Person"] } },
      { name: "Sliding Scale", field_type: "boolean", required: false, help_text: "Income-based pricing available" }
    ]
  },
  {
    name: "Pediatricians",
    slug: "pediatricians",
    description: "Medical care for children and adolescents",
    display_order: 6,
    fields: [
      { name: "Specialties", field_type: "multi_select", required: true, options: { choices: ["General Pediatrics", "Developmental Pediatrics", "Behavioral Pediatrics", "Autism Specialist", "ADHD Specialist"] } },
      { name: "Board Certifications", field_type: "select", required: true, options: { choices: ["Board Certified Pediatrician", "Fellowship Trained", "Developmental Pediatrician", "Behavioral Pediatrician"] } },
      { name: "Age Range", field_type: "select", required: true, options: { choices: ["0-3", "3-5", "5-12", "12-18", "18-21", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "Sliding Scale"] } },
      { name: "Waitlist Status", field_type: "select", required: false, options: { choices: ["Accepting New Patients", "Short Waitlist", "Long Waitlist", "Not Accepting"] } }
    ]
  },
  {
    name: "Orthodontists",
    slug: "orthodontists",
    description: "Orthodontic care and braces for all ages",
    display_order: 7,
    fields: [
      { name: "Services", field_type: "multi_select", required: true, options: { choices: ["Traditional Braces", "Clear Aligners", "Early Intervention", "Adult Orthodontics", "Surgical Orthodontics"] } },
      { name: "Certifications", field_type: "select", required: true, options: { choices: ["Board Certified Orthodontist", "DDS/DMD", "Orthodontic Specialist"] } },
      { name: "Age Groups", field_type: "select", required: true, options: { choices: ["7-12 (Early Treatment)", "12-18 (Teen)", "18+ (Adult)", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Dental Insurance", "Medical Insurance", "Self-Pay", "Payment Plans"] } },
      { name: "Free Consultations", field_type: "boolean", required: false, help_text: "Free initial consultation available" }
    ]
  },
  {
    name: "Dentists",
    slug: "dentists",
    description: "General and specialized dental care",
    display_order: 8,
    fields: [
      { name: "Specialties", field_type: "multi_select", required: true, options: { choices: ["General Dentistry", "Pediatric Dentistry", "Special Needs Dentistry", "Sedation Dentistry", "Emergency Care"] } },
      { name: "Certifications", field_type: "select", required: true, options: { choices: ["DDS", "DMD", "Board Certified", "Pediatric Specialist"] } },
      { name: "Age Groups", field_type: "select", required: true, options: { choices: ["0-3", "3-5", "5-12", "12-18", "18+", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Dental Insurance", "Medicaid", "Private Insurance", "Self-Pay", "Payment Plans"] } },
      { name: "Special Needs Accommodations", field_type: "boolean", required: false, help_text: "Special accommodations for special needs patients" }
    ]
  },
  {
    name: "Physical Therapists",
    slug: "physical_therapists",
    description: "Physical therapy and rehabilitation services",
    display_order: 9,
    fields: [
      { name: "Specialties", field_type: "multi_select", required: true, options: { choices: ["Pediatric PT", "Neurological PT", "Orthopedic PT", "Sports PT", "Developmental PT"] } },
      { name: "Certifications", field_type: "select", required: true, options: { choices: ["PT", "DPT", "Licensed Physical Therapist", "Pediatric Specialist"] } },
      { name: "Age Groups", field_type: "select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "School District Contracts"] } },
      { name: "Home Visits", field_type: "boolean", required: false, help_text: "Home-based therapy available" }
    ]
  },
  {
    name: "Barbers/Hair",
    slug: "barbers_hair",
    description: "Hair care services for all ages",
    display_order: 10,
    fields: [
      { name: "Services", field_type: "multi_select", required: true, options: { choices: ["Haircuts", "Hair Styling", "Special Needs Haircuts", "Sensory-Friendly", "Mobile Services"] } },
      { name: "Experience", field_type: "select", required: true, options: { choices: ["Special Needs Experience", "Pediatric Experience", "General Experience", "Certified Stylist"] } },
      { name: "Age Groups", field_type: "select", required: true, options: { choices: ["0-3", "3-5", "5-12", "12-18", "18+", "All Ages"] } },
      { name: "Pricing", field_type: "select", required: false, options: { choices: ["Standard Pricing", "Special Needs Pricing", "Sliding Scale", "Insurance Accepted"] } },
      { name: "Mobile Services", field_type: "boolean", required: false, help_text: "Home or mobile haircut services" }
    ]
  },
  {
    name: "Advocates",
    slug: "advocates",
    description: "Autism and disability advocacy services",
    display_order: 11,
    fields: [
      { name: "Advocacy Areas", field_type: "multi_select", required: true, options: { choices: ["Education Rights", "Healthcare Access", "Employment", "Housing", "Legal Rights", "Benefits"] } },
      { name: "Credentials", field_type: "select", required: true, options: { choices: ["Certified Advocate", "Attorney", "Social Worker", "Parent Advocate", "Professional Advocate"] } },
      { name: "Age Groups", field_type: "select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)", "All Ages"] } },
      { name: "Services", field_type: "select", required: false, options: { choices: ["Individual Advocacy", "Group Advocacy", "Legal Representation", "Consultation", "Training"] } },
      { name: "Sliding Scale", field_type: "boolean", required: false, help_text: "Income-based pricing available" }
    ]
  },
  {
    name: "Therapists",
    slug: "therapists",
    description: "Mental health and behavioral therapy",
    display_order: 12,
    fields: [
      { name: "Therapy Types", field_type: "multi_select", required: true, options: { choices: ["Individual Therapy", "Family Therapy", "Group Therapy", "Play Therapy", "CBT", "DBT"] } },
      { name: "Licenses", field_type: "select", required: true, options: { choices: ["Licensed Therapist", "Licensed Counselor", "Licensed Social Worker", "Psychologist", "Psychiatrist"] } },
      { name: "Age Groups", field_type: "select", required: true, options: { choices: ["0-3", "3-5", "5-12", "12-18", "18+", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "Sliding Scale"] } },
      { name: "Special Needs Experience", field_type: "boolean", required: false, help_text: "Experience with autism and special needs" }

    ]
  }
]

categories.each do |category_data|
  fields_data = category_data.delete(:fields)
  
  # Find or create the category
  category = ProviderCategory.find_or_create_by(slug: category_data[:slug])
  
  # Update attributes if category exists, or assign if new
  if category.persisted?
    category.update!(category_data)
  else
    category.assign_attributes(category_data)
    category.save!
  end
  
  puts "✅ Created/Updated category: #{category.name}"
  
  # Create fields for this category
  fields_data.each_with_index do |field_data, index|
    # Extract options from the nested structure
    options_data = field_data[:options]
    field_options = options_data[:choices] if options_data && options_data[:choices]
    
    field = category.category_fields.find_or_create_by(name: field_data[:name]) do |f|
      f.assign_attributes(
        field_type: field_data[:field_type],
        required: field_data[:required],
        options: field_options,
        display_order: index + 1,
        help_text: field_data[:help_text]
      )
    end
    
    # Update existing fields
    if field.persisted?
      field.update!(
        field_type: field_data[:field_type],
        required: field_data[:required],
        options: field_options,
        display_order: index + 1,
        help_text: field_data[:help_text]
      )
    end
    
    puts "  📝 Field: #{field.name} (#{field.field_type})"
  end
end

puts "🎉 Provider categories and fields seeded successfully!"
puts "📊 Total categories: #{ProviderCategory.count}"
puts "📝 Total fields: #{CategoryField.count}" 