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
      { name: "Speech Specialties", field_type: "multi_select", required: true, options: { choices: ["Articulation Disorders", "Language Delays", "Stuttering", "Voice Disorders", "Swallowing Disorders", "Social Communication", "AAC (Augmentative Communication)"] } },
      { name: "Credentials", field_type: "select", required: true, options: { choices: ["Licensed Speech-Language Pathologist", "ASHA Certified", "State Licensed", "Early Intervention Certified"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)"] } },
      { name: "Service Delivery", field_type: "multi_select", required: true, options: { choices: ["In-Person", "Teletherapy", "Home Visits", "School-Based", "Clinic-Based"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "Sliding Scale", "School District Contracts"] } }
    ]
  },
  {
    name: "Occupational Therapy",
    slug: "occupational_therapy",
    description: "Occupational therapy and sensory integration services",
    display_order: 4,
    fields: [
      { name: "OT Specialties", field_type: "multi_select", required: true, options: { choices: ["Sensory Integration", "Fine Motor Skills", "Gross Motor Skills", "Activities of Daily Living", "Handwriting", "Visual Motor Skills", "Feeding Therapy", "Adaptive Equipment"] } },
      { name: "Credentials", field_type: "select", required: true, options: { choices: ["Licensed Occupational Therapist", "NBCOT Certified", "State Licensed", "Early Intervention Certified", "Sensory Integration Certified"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)"] } },
      { name: "Service Delivery", field_type: "multi_select", required: true, options: { choices: ["In-Person", "Teletherapy", "Home Visits", "School-Based", "Clinic-Based", "Community-Based"] } },
      { name: "Equipment Available", field_type: "multi_select", required: false, options: { choices: ["Sensory Gym", "Adaptive Equipment", "Fine Motor Tools", "Gross Motor Equipment", "Feeding Tools", "Handwriting Aids"] } }
    ]
  },
  {
    name: "Dentists",
    slug: "dentists",
    description: "Dental care providers",
    display_order: 5,
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
    display_order: 6,
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
    display_order: 7,
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
    display_order: 8,
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
    display_order: 9,
    fields: [
      { name: "Specialties", field_type: "select", required: true, options: { choices: ["Autism Rights", "Disability Rights", "Education Rights", "Healthcare Rights", "Employment Rights"] } },
      { name: "Services", field_type: "select", required: true, options: { choices: ["Legal Representation", "Case Management", "Rights Education", "Mediation", "Appeals"] } },
      { name: "Geographic Coverage", field_type: "text", required: true, help_text: "Counties or regions served" },
      { name: "Fee Structure", field_type: "select", required: false, options: { choices: ["Free", "Sliding Scale", "Hourly Rate", "Flat Fee", "Pro Bono"] } },
      { name: "Languages", field_type: "select", required: false, options: { choices: ["English", "Spanish", "ASL", "Other"] } }
    ]
  },
  {
    name: "Coaching/Mentoring",
    slug: "coaching_mentoring",
    description: "Life coaching and mentoring services for individuals with autism and their families",
    display_order: 10,
    fields: [
      { name: "Coaching Focus", field_type: "multi_select", required: true, options: { choices: ["Life Skills", "Social Skills", "Executive Functioning", "Career Development", "Parent Coaching", "Sibling Support", "Transition Planning", "Self-Advocacy"] } },
      { name: "Credentials", field_type: "select", required: true, options: { choices: ["Certified Life Coach", "Certified Autism Specialist", "Licensed Professional", "Board Certified Coach", "Parent Coach Certification", "Special Education Background"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["Children (5-12)", "Teens (13-18)", "Young Adults (18-25)", "Adults (25+)", "Parents/Families", "All Ages"] } },
      { name: "Service Delivery", field_type: "multi_select", required: true, options: { choices: ["In-Person", "Virtual/Online", "Group Sessions", "One-on-One", "Family Sessions", "Community Outings"] } },
      { name: "Fee Structure", field_type: "select", required: false, options: { choices: ["Hourly Rate", "Package Deals", "Sliding Scale", "Insurance Accepted", "Scholarships Available"] } }
    ]
  },
  {
    name: "Pediatricians",
    slug: "pediatricians",
    description: "Pediatric medical care providers with special needs experience",
    display_order: 11,
    fields: [
      { name: "Specialties", field_type: "multi_select", required: true, options: { choices: ["General Pediatrics", "Developmental Pediatrics", "Behavioral Pediatrics", "Neurodevelopmental Pediatrics", "Adolescent Medicine", "Special Needs Pediatrics"] } },
      { name: "Credentials", field_type: "select", required: true, options: { choices: ["Board Certified Pediatrician", "Developmental-Behavioral Pediatrics Certified", "Neurodevelopmental Disabilities Certified", "State Licensed", "Fellowship Trained"] } },
      { name: "Age Range", field_type: "select", required: true, options: { choices: ["0-3 (Infants/Toddlers)", "3-12 (Children)", "12-18 (Adolescents)", "0-18 (All Pediatric Ages)", "18-21 (Young Adults)"] } },
      { name: "Services Offered", field_type: "multi_select", required: true, options: { choices: ["Well Child Visits", "Developmental Screenings", "Autism Evaluations", "Behavioral Consultations", "Medication Management", "Referral Coordination", "Care Coordination"] } },
      { name: "Insurance Accepted", field_type: "select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "Sliding Scale", "School District Contracts"] } }
    ]
  },
  {
    name: "Orthodontists",
    slug: "orthodontists",
    description: "Orthodontic and dental alignment specialists",
    display_order: 12,
    fields: [
      { name: "Orthodontic Specialties", field_type: "multi_select", required: true, options: { choices: ["Traditional Braces", "Clear Aligners", "Early Intervention", "Surgical Orthodontics", "Craniofacial Orthodontics", "Special Needs Orthodontics"] } },
      { name: "Credentials", field_type: "select", required: true, options: { choices: ["Board Certified Orthodontist", "State Licensed", "Fellowship Trained", "Special Needs Experience", "Pediatric Orthodontics Certified"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["Children (7-12)", "Teens (13-18)", "Adults (18+)", "All Ages", "Early Intervention (7-10)"] } },
      { name: "Treatment Options", field_type: "multi_select", required: true, options: { choices: ["Metal Braces", "Ceramic Braces", "Clear Aligners", "Retainers", "Expansion Appliances", "Headgear", "Surgical Options"] } },
      { name: "Special Accommodations", field_type: "multi_select", required: false, options: { choices: ["Sensory-Friendly Environment", "Extended Appointment Times", "Sedation Options", "Home Visits", "Flexible Scheduling", "Parent Support"] } }
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

puts "🎉 Provider categories seeding complete!"
puts "📊 Total categories: #{ProviderCategory.count}"
puts "📝 Total fields: #{CategoryField.count}" 