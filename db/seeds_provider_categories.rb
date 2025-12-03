
# Seeds for Provider Categories and Fields
puts "🌱 Seeding provider categories and fields..."

categories = [
  {
    name: "ABA Therapy",
    slug: "aba_therapy",
    description: "Applied Behavior Analysis therapy providers",
    display_order: 1,
    fields: [
      { name: "Specialties", field_type: "multi_select", required: true, options: { choices: ["Autism", "ADHD", "Behavioral Issues", "Developmental Delays", "Social Skills", "Anxiety", "Depression", "OCD", "Tourette's", "Learning Disabilities"] } },
      { name: "Certifications", field_type: "multi_select", required: true, options: { choices: ["BCBA", "BCaBA", "RBT", "Licensed Therapist", "Licensed Psychologist", "Licensed Social Worker", "Licensed Counselor"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3", "3-5", "5-12", "12-18", "18+", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "multi_select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "Flexible pricing based on your circumstances", "School District Contracts", "Medicare", "Tricare"] } },
      { name: "Emergency Services", field_type: "boolean", required: false, help_text: "Available for urgent behavioral needs" }
    ]
  },
  {
    name: "Autism Evaluations",
    slug: "autism_evaluations",
    description: "Professional autism assessment and diagnostic services",
    display_order: 2,
    fields: [
      { name: "Evaluation Types", field_type: "multi_select", required: true, options: { choices: ["ADOS-2", "ADI-R", "CARS-2", "GARS-3", "M-CHAT", "Comprehensive Assessment", "Cognitive Testing", "Adaptive Behavior", "Language Assessment", "Motor Skills Assessment"] } },
      { name: "Credentials", field_type: "multi_select", required: true, options: { choices: ["Licensed Psychologist", "Developmental Pediatrician", "Child Psychiatrist", "Licensed Clinical Social Worker", "Board Certified Behavior Analyst", "Neuropsychologist", "School Psychologist", "Licensed Professional Counselor"] } },
      { name: "Age Range Served", field_type: "multi_select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "multi_select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "Flexible pricing based on your circumstances", "School District Contracts", "Medicare", "Tricare"] } },
      { name: "Report Turnaround", field_type: "select", required: false, options: { choices: ["1-2 weeks", "2-4 weeks", "4-6 weeks", "6+ weeks"] } }
    ]
  },
  {
    name: "Speech Therapy",
    slug: "speech_therapy",
    description: "Speech and language therapy services",
    display_order: 3,
    fields: [
      { name: "Speech Disorders", field_type: "multi_select", required: true, options: { choices: ["Articulation", "Language Delay", "Stuttering", "Voice Disorders", "Swallowing", "Social Communication", "Apraxia", "Dysarthria", "Phonological Disorders", "Fluency Disorders"] } },
      { name: "Certifications", field_type: "multi_select", required: true, options: { choices: ["SLP", "SLPA", "CCC-SLP", "Licensed Speech Therapist", "Board Certified", "Specialist Certification", "Pediatric Specialist"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "multi_select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "School District Contracts", "Medicare", "Tricare", "Flexible pricing based on your circumstances"] } },
      { name: "Teletherapy Available", field_type: "boolean", required: false, help_text: "Virtual therapy sessions available" }
    ]
  },
  {
    name: "Occupational Therapy",
    slug: "occupational_therapy",
    description: "Occupational therapy for developmental and sensory needs",
    display_order: 4,
    fields: [
      { name: "Focus Areas", field_type: "multi_select", required: true, options: { choices: ["Sensory Processing", "Fine Motor Skills", "Gross Motor Skills", "ADL Training", "Handwriting", "Visual Motor", "Feeding Therapy", "Dressing Skills", "Play Skills", "Social Skills", "Executive Functioning"] } },
      { name: "Certifications", field_type: "multi_select", required: true, options: { choices: ["OT", "OTA", "Licensed Occupational Therapist", "Board Certified", "Pediatric Specialist", "Sensory Integration Certified", "Feeding Specialist"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "multi_select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "School District Contracts", "Medicare", "Tricare", "Flexible pricing based on your circumstances"] } },
      { name: "Sensory Integration", field_type: "boolean", required: false, help_text: "Specialized sensory integration therapy" }
    ]
  },
  {
    name: "Coaching/Mentoring",
    slug: "coaching_mentoring",
    description: "Life skills coaching and mentoring services",
    display_order: 5,
    fields: [
      { name: "Coaching Areas", field_type: "multi_select", required: true, options: { choices: ["Life Skills", "Social Skills", "Executive Functioning", "Career Development", "Independent Living", "Relationship Skills", "Communication", "Emotional Regulation", "Problem Solving", "Goal Setting", "Time Management"] } },
      { name: "Credentials", field_type: "multi_select", required: true, options: { choices: ["Certified Coach", "Licensed Counselor", "Social Worker", "Life Coach", "Mentor", "Board Certified", "Special Education Teacher", "Behavioral Specialist", "Parent Coach"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["12-18 (Teen)", "18-25 (Young Adult)", "25+ (Adult)", "All Ages"] } },
      { name: "Session Format", field_type: "multi_select", required: false, options: { choices: ["Individual", "Group", "Family", "Virtual", "In-Person", "Phone", "Text/Email Support"] } },
      { name: "Flexible Pricing", field_type: "boolean", required: false, help_text: "Pricing varies based on your specific situation and needs" }
    ]
  },
  {
    name: "Pediatricians",
    slug: "pediatricians",
    description: "Medical care for children and adolescents",
    display_order: 6,
    fields: [
      { name: "Specialties", field_type: "multi_select", required: true, options: { choices: ["General Pediatrics", "Developmental Pediatrics", "Behavioral Pediatrics", "Autism Specialist", "ADHD Specialist", "Neurology", "Cardiology", "Endocrinology", "Gastroenterology", "Allergy/Immunology"] } },
      { name: "Board Certifications", field_type: "multi_select", required: true, options: { choices: ["Board Certified Pediatrician", "Fellowship Trained", "Developmental Pediatrician", "Behavioral Pediatrician", "Subspecialty Board Certified", "Pediatric Neurology", "Pediatric Psychiatry"] } },
      { name: "Age Range", field_type: "multi_select", required: true, options: { choices: ["0-3", "3-5", "5-12", "12-18", "18-21", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "multi_select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "Flexible pricing based on your circumstances", "Medicare", "Tricare", "CHIP"] } },
      { name: "Waitlist Status", field_type: "select", required: false, options: { choices: ["Accepting New Patients", "Short Waitlist", "Long Waitlist", "Not Accepting"] } }
    ]
  },
  {
    name: "Orthodontists",
    slug: "orthodontists",
    description: "Orthodontic care and braces for all ages",
    display_order: 7,
    fields: [
      { name: "Services", field_type: "multi_select", required: true, options: { choices: ["Traditional Braces", "Clear Aligners", "Early Intervention", "Adult Orthodontics", "Surgical Orthodontics", "Retainers", "Expansion Appliances", "Space Maintainers", "Habit Appliances"] } },
      { name: "Certifications", field_type: "multi_select", required: true, options: { choices: ["Board Certified Orthodontist", "DDS/DMD", "Orthodontic Specialist", "Fellowship Trained", "Pediatric Dentistry", "Special Needs Experience"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["7-12 (Early Treatment)", "12-18 (Teen)", "18+ (Adult)", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "multi_select", required: false, options: { choices: ["Dental Insurance", "Medical Insurance", "Self-Pay", "Payment Plans", "Medicaid", "Medicare", "Tricare"] } },
      { name: "Free Consultations", field_type: "boolean", required: false, help_text: "Free initial consultation available" }
    ]
  },
  {
    name: "Dentists",
    slug: "dentists",
    description: "General and specialized dental care",
    display_order: 8,
    fields: [
      { name: "Services", field_type: "multi_select", required: true, options: { choices: ["General Dentistry", "Pediatric Dentistry", "Special Needs Dentistry", "Preventive Care", "Restorative", "Orthodontics", "Endodontics", "Periodontics", "Oral Surgery", "Emergency Care"] } },
      { name: "Credentials", field_type: "multi_select", required: true, options: { choices: ["DDS", "DMD", "Licensed Dentist", "Pediatric Specialist", "Special Needs Experience", "Board Certified", "Fellowship Trained"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3", "3-5", "5-12", "12-18", "18+", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "multi_select", required: false, options: { choices: ["Dental Insurance", "Medical Insurance", "Self-Pay", "Payment Plans", "Medicaid", "Medicare", "Tricare", "CHIP"] } },
      { name: "Sedation Available", field_type: "boolean", required: false, help_text: "Sedation options for anxious patients" }
    ]
  },
  {
    name: "Physical Therapy",
    slug: "physical_therapy",
    description: "Physical therapy and rehabilitation services",
    display_order: 9,
    fields: [
      { name: "Specialties", field_type: "multi_select", required: true, options: { choices: ["Pediatric PT", "Neurological PT", "Orthopedic PT", "Sports PT", "Developmental PT", "Aquatic Therapy", "Vestibular Therapy", "Cardiopulmonary PT", "Geriatric PT", "Women's Health PT"] } },
      { name: "Certifications", field_type: "multi_select", required: true, options: { choices: ["PT", "DPT", "Licensed Physical Therapist", "Pediatric Specialist", "Board Certified", "Neurologic Specialist", "Orthopedic Specialist", "Sports Specialist"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "multi_select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "School District Contracts", "Medicare", "Tricare", "Workers Comp", "Auto Insurance"] } },
      { name: "Home Visits", field_type: "boolean", required: false, help_text: "Home-based therapy available" }
    ]
  },
  {
    name: "Barbers/Hair",
    slug: "barbers_hair",
    description: "Hair care services for all ages",
    display_order: 10,
    fields: [
      { name: "Services", field_type: "multi_select", required: true, options: { choices: ["Haircuts", "Hair Styling", "Special Needs Haircuts", "Sensory-Friendly", "Mobile Services", "Hair Coloring", "Hair Extensions", "Braiding", "Hair Treatments", "Kids Haircuts"] } },
      { name: "Experience", field_type: "multi_select", required: true, options: { choices: ["Special Needs Experience", "Pediatric Experience", "General Experience", "Certified Stylist", "Licensed Cosmetologist", "Barber License", "Specialized Training", "Continuing Education"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3", "3-5", "5-12", "12-18", "18+", "All Ages"] } },
      { name: "Pricing", field_type: "multi_select", required: false, options: { choices: ["Standard Pricing", "Special Needs Pricing", "Flexible pricing based on your circumstances", "Insurance Accepted", "Package Deals", "Family Discounts"] } },
      { name: "Mobile Services", field_type: "boolean", required: false, help_text: "Home or mobile haircut services" }
    ]
  },
  {
    name: "Advocates",
    slug: "advocates",
    description: "Autism and disability advocacy services",
    display_order: 11,
    fields: [
      { name: "Advocacy Areas", field_type: "multi_select", required: true, options: { choices: ["Education Rights", "Healthcare Access", "Employment", "Housing", "Legal Rights", "Benefits", "Transportation", "Recreation", "Technology Access", "Independent Living", "Guardianship", "Estate Planning"] } },
      { name: "Credentials", field_type: "multi_select", required: true, options: { choices: ["Certified Advocate", "Attorney", "Social Worker", "Parent Advocate", "Professional Advocate", "Board Certified", "Special Education Background", "Legal Training", "Healthcare Background"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (Preschool)", "5-12 (School Age)", "12-18 (Adolescent)", "18+ (Adult)", "All Ages"] } },
      { name: "Services", field_type: "multi_select", required: false, options: { choices: ["Individual Advocacy", "Group Advocacy", "Legal Representation", "Consultation", "Training", "Mediation", "Documentation Review", "Meeting Attendance", "Appeal Support"] } },
      { name: "Flexible Pricing", field_type: "boolean", required: false, help_text: "Pricing varies based on your specific situation and needs" }
    ]
  },
  {
    name: "Therapists",
    slug: "therapists",
    description: "Mental health and behavioral therapy",
    display_order: 12,
    fields: [
      { name: "Therapy Types", field_type: "multi_select", required: true, options: { choices: ["Individual Therapy", "Family Therapy", "Group Therapy", "Play Therapy", "CBT", "DBT", "Art Therapy", "Music Therapy", "Animal-Assisted Therapy", "Trauma Therapy", "Anxiety Therapy", "Depression Therapy"] } },
      { name: "Licenses", field_type: "multi_select", required: true, options: { choices: ["Licensed Therapist", "Licensed Counselor", "Licensed Social Worker", "Psychologist", "Psychiatrist", "Marriage & Family Therapist", "Professional Counselor", "Clinical Social Worker", "Board Certified"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3", "3-5", "5-12", "12-18", "18+", "All Ages"] } },
      { name: "Insurance Accepted", field_type: "multi_select", required: false, options: { choices: ["Medicaid", "Private Insurance", "Self-Pay", "Flexible pricing based on your circumstances", "Medicare", "Tricare", "School District Contracts"] } },
      { name: "Special Needs Experience", field_type: "boolean", required: false, help_text: "Experience with autism and special needs" }
    ]
  },
  {
    name: "Educational Programs",
    slug: "educational_programs",
    description: "Online and in-person learning programs for early childhood education, often integrated with ABA therapy or early education settings",
    display_order: 13,
    fields: [
      { name: "Program Types", field_type: "multi_select", required: true, options: { choices: ["Early Learning Programs", "PreK-2 Curriculum", "Reading Programs", "Math Programs", "Social Skills Programs", "Language Development", "Cognitive Development", "ABA-Integrated Programs", "Early Education Support", "Homeschool Support", "Supplemental Learning", "Online Learning Platforms"] } },
      { name: "Credentials/Qualifications", field_type: "multi_select", required: true, options: { choices: ["Licensed Teacher", "Certified Educator", "Early Childhood Specialist", "Special Education Teacher", "BCBA/ABA Specialist", "Curriculum Developer", "Educational Therapist", "Learning Specialist", "Non-Profit Organization", "Accredited Program"] } },
      { name: "Age Groups", field_type: "multi_select", required: true, options: { choices: ["0-3 (Early Intervention)", "3-5 (PreK)", "5-7 (Kindergarten-2nd Grade)", "3-8 (PreK-2nd Grade)", "All Ages"] } },
      { name: "Delivery Format", field_type: "multi_select", required: true, options: { choices: ["Online Only", "In-Person", "Hybrid (Online + In-Person)", "Self-Paced Online", "Live Online Sessions", "Recorded Content", "Interactive Platform"] } },
      { name: "Integration Options", field_type: "multi_select", required: false, options: { choices: ["ABA Therapy Integration", "Early Education Integration", "School Integration", "Homeschool Integration", "Therapy Integration", "Standalone Program"] } },
      { name: "Pricing", field_type: "multi_select", required: false, options: { choices: ["Free", "Sliding Scale", "Subscription-Based", "One-Time Fee", "Grant-Funded", "Non-Profit Pricing", "Flexible pricing based on your circumstances", "School District Contracts"] } },
      { name: "Parent/Caregiver Support", field_type: "boolean", required: false, help_text: "Includes training or support for parents/caregivers" }
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
    # Generate slug for the field
    field_slug = field_data[:name].downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
    
    # Extract options from the nested structure
    options_data = field_data[:options]
    field_options = options_data[:choices] if options_data && options_data[:choices]
    
    field = category.category_fields.find_or_create_by(name: field_data[:name]) do |f|
      f.assign_attributes(
        field_type: field_data[:field_type],
        required: field_data[:required],
        options: field_options,
        display_order: index + 1,
        help_text: field_data[:help_text],
        slug: field_slug
      )
    end
    
    # Update existing fields
    if field.persisted?
      field.update!(
        field_type: field_data[:field_type],
        required: field_data[:required],
        options: field_options,
        display_order: index + 1,
        help_text: field_data[:help_text],
        slug: field_slug
      )
    end
    
    puts "  📝 Field: #{field.name} (#{field.field_type})"
  end
end

puts "🎉 Provider categories and fields seeded successfully!"
puts "📊 Total categories: #{ProviderCategory.count}"
puts "📝 Total fields: #{CategoryField.count}" 