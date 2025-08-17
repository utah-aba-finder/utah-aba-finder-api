puts "🚀 Adding all missing category fields..."

# Autism Evaluations
puts "📋 Adding Autism Evaluations fields..."
autism_eval = ProviderCategory.find_by(slug: 'autism_evaluations')
if autism_eval
  autism_eval.category_fields.create!([
    { name: 'Evaluation Types', field_type: 'multi_select', required: true, options: { choices: ['ADOS-2', 'ADI-R', 'CARS-2', 'GARS-3', 'M-CHAT', 'Comprehensive Assessment'] }, display_order: 1 },
    { name: 'Credentials', field_type: 'select', required: true, options: { choices: ['Licensed Psychologist', 'Developmental Pediatrician', 'Child Psychiatrist', 'Licensed Clinical Social Worker', 'Board Certified Behavior Analyst'] }, display_order: 2 },
    { name: 'Age Range Served', field_type: 'select', required: true, options: { choices: ['0-3 (Early Intervention)', '3-5 (Preschool)', '5-12 (School Age)', '12-18 (Adolescent)', '18+ (Adult)', 'All Ages'] }, display_order: 3 },
    { name: 'Insurance Accepted', field_type: 'select', required: false, options: { choices: ['Medicaid', 'Private Insurance', 'Self-Pay', 'Sliding Scale', 'School District Contracts'] }, display_order: 4 },
    { name: 'Report Turnaround', field_type: 'select', required: false, options: { choices: ['1-2 weeks', '2-4 weeks', '4-6 weeks', '6+ weeks'] }, display_order: 5 }
  ])
  puts "✅ Autism Evaluations - 5 fields added"
end

# Speech Therapy
puts "🗣️ Adding Speech Therapy fields..."
speech = ProviderCategory.find_by(slug: 'speech_therapy')
if speech
  speech.category_fields.create!([
    { name: 'Specialties', field_type: 'multi_select', required: true, options: { choices: ['Articulation', 'Language Development', 'Fluency/Stuttering', 'Voice Disorders', 'Swallowing Disorders', 'Social Communication'] }, display_order: 1 },
    { name: 'Credentials', field_type: 'select', required: true, options: { choices: ['Speech-Language Pathologist (SLP)', 'Licensed SLP', 'ASHA Certified', 'Clinical Fellow', 'Specialist Certification'] }, display_order: 2 },
    { name: 'Age Range Served', field_type: 'select', required: true, options: { choices: ['0-3 (Early Intervention)', '3-5 (Preschool)', '5-12 (School Age)', '12-18 (Adolescent)', '18+ (Adult)', 'All Ages'] }, display_order: 3 },
    { name: 'Insurance Accepted', field_type: 'select', required: false, options: { choices: ['Medicaid', 'Private Insurance', 'Self-Pay', 'Sliding Scale', 'School District Contracts'] }, display_order: 4 },
    { name: 'Teletherapy', field_type: 'boolean', required: false, options: {}, help_text: 'Available for online sessions' }
  ])
  puts "✅ Speech Therapy - 5 fields added"
end

# Occupational Therapy
puts "🏥 Adding Occupational Therapy fields..."
ot = ProviderCategory.find_by(slug: 'occupational_therapy')
if ot
  ot.category_fields.create!([
    { name: 'Specialties', field_type: 'multi_select', required: true, options: { choices: ['Pediatric OT', 'Sensory Integration', 'Fine Motor Skills', 'Gross Motor Skills', 'ADL Training', 'Hand Therapy'] }, display_order: 1 },
    { name: 'Credentials', field_type: 'select', required: true, options: { choices: ['Occupational Therapist (OT)', 'Licensed OT', 'NBCOT Certified', 'Specialist Certification', 'Advanced Practice'] }, display_order: 2 },
    { name: 'Age Range Served', field_type: 'select', required: true, options: { choices: ['0-3 (Early Intervention)', '3-5 (Preschool)', '5-12 (School Age)', '12-18 (Adolescent)', '18+ (Adult)', 'All Ages'] }, display_order: 3 },
    { name: 'Insurance Accepted', field_type: 'select', required: false, options: { choices: ['Medicaid', 'Private Insurance', 'Self-Pay', 'Sliding Scale', 'School District Contracts'] }, display_order: 4 },
    { name: 'Home Visits', field_type: 'boolean', required: false, options: {}, help_text: 'Provides in-home occupational therapy' }
  ])
  puts "✅ Occupational Therapy - 5 fields added"
end

# Coaching/Mentoring
puts "🎯 Adding Coaching/Mentoring fields..."
coaching = ProviderCategory.find_by(slug: 'coaching_mentoring')
if coaching
  coaching.category_fields.create!([
    { name: 'Specialties', field_type: 'multi_select', required: true, options: { choices: ['Life Coaching', 'Career Coaching', 'Parent Coaching', 'Executive Coaching', 'Wellness Coaching', 'Academic Coaching'] }, display_order: 1 },
    { name: 'Credentials', field_type: 'select', required: true, options: { choices: ['Certified Life Coach', 'Professional Coach', 'Licensed Therapist', 'Certified Parent Coach', 'Executive Coach', 'Wellness Coach'] }, display_order: 2 },
    { name: 'Age Range Served', field_type: 'select', required: true, options: { choices: ['Children (5-12)', 'Teens (13-18)', 'Young Adults (18-25)', 'Adults (25+)', 'All Ages'] }, display_order: 3 },
    { name: 'Insurance Accepted', field_type: 'select', required: false, options: { choices: ['Private Insurance', 'Self-Pay', 'Sliding Scale', 'Employee Benefits', 'Not Applicable'] }, display_order: 4 },
    { name: 'Session Types', field_type: 'multi_select', required: false, options: { choices: ['Individual Sessions', 'Group Sessions', 'Family Sessions', 'Online/Video', 'Phone Sessions'] }, display_order: 5 }
  ])
  puts "✅ Coaching/Mentoring - 5 fields added"
end

# Pediatricians
puts "👶 Adding Pediatricians fields..."
pediatricians = ProviderCategory.find_by(slug: 'pediatricians')
if pediatricians
  pediatricians.category_fields.create!([
    { name: 'Specialties', field_type: 'multi_select', required: true, options: { choices: ['General Pediatrics', 'Developmental Pediatrics', 'Behavioral Pediatrics', 'Adolescent Medicine', 'Special Needs Pediatrics'] }, display_order: 1 },
    { name: 'Insurance Accepted', field_type: 'select', required: false, options: { choices: ['Medicaid', 'Private Insurance', 'CHIP', 'Self-Pay', 'Sliding Scale'] }, display_order: 2 },
    { name: 'Emergency Services', field_type: 'boolean', required: false, options: {}, help_text: 'Available for urgent care needs' },
    { name: 'Special Needs Experience', field_type: 'boolean', required: false, options: {}, help_text: 'Experience with special needs patients' },
    { name: 'Languages', field_type: 'multi_select', required: false, options: { choices: ['English', 'Spanish', 'ASL', 'Other'] } }
  ])
  puts "✅ Pediatricians - 5 fields added"
end

# Orthodontists
puts "🦷 Adding Orthodontists fields..."
orthodontists = ProviderCategory.find_by(slug: 'orthodontists')
if orthodontists
  orthodontists.category_fields.create!([
    { name: 'Specialties', field_type: 'multi_select', required: true, options: { choices: ['Traditional Braces', 'Clear Aligners', 'Early Intervention', 'Adult Orthodontics', 'Surgical Orthodontics'] }, display_order: 1 },
    { name: 'Insurance Accepted', field_type: 'select', required: false, options: { choices: ['Delta Dental', 'MetLife', 'Aetna', 'Cigna', 'Self-Pay', 'Payment Plans'] }, display_order: 2 },
    { name: 'Emergency Services', field_type: 'boolean', required: false, options: {}, help_text: 'Available for urgent orthodontic needs' },
    { name: 'Special Needs Experience', field_type: 'boolean', required: false, options: {}, help_text: 'Experience with special needs patients' },
    { name: 'Payment Plans', field_type: 'boolean', required: false, options: {}, help_text: 'Offers flexible payment options' }
  ])
  puts "✅ Orthodontists - 5 fields added"
end

puts "\n🎉 ALL CATEGORY FIELDS COMPLETED SUCCESSFULLY!"
puts "📊 Final Counts:"
puts "   Total Categories: #{ProviderCategory.count}"
puts "   Total Fields: #{CategoryField.count}"
puts "   Categories with Fields: #{ProviderCategory.joins(:category_fields).distinct.count}"
puts "\n🚀 Your provider registration system is now fully functional!" 