puts "Adding missing category fields..."

# Autism Evaluations
puts "Adding Autism Evaluations fields..."
autism_eval = ProviderCategory.find_by(slug: 'autism_evaluations')
if autism_eval
  autism_eval.category_fields.create!(name: 'Evaluation Types', field_type: 'multi_select', required: true, options: { choices: ['ADOS-2', 'ADI-R', 'CARS-2', 'GARS-3', 'M-CHAT', 'Comprehensive Assessment'] }, display_order: 1)
  autism_eval.category_fields.create!(name: 'Credentials', field_type: 'select', required: true, options: { choices: ['Licensed Psychologist', 'Developmental Pediatrician', 'Child Psychiatrist', 'Licensed Clinical Social Worker', 'Board Certified Behavior Analyst'] }, display_order: 2)
  autism_eval.category_fields.create!(name: 'Age Range Served', field_type: 'select', required: true, options: { choices: ['0-3 (Early Intervention)', '3-5 (Preschool)', '5-12 (School Age)', '12-18 (Adolescent)', '18+ (Adult)', 'All Ages'] }, display_order: 3)
  autism_eval.category_fields.create!(name: 'Insurance Accepted', field_type: 'select', required: false, options: { choices: ['Medicaid', 'Private Insurance', 'Self-Pay', 'Sliding Scale', 'School District Contracts'] }, display_order: 4)
  autism_eval.category_fields.create!(name: 'Report Turnaround', field_type: 'select', required: false, options: { choices: ['1-2 weeks', '2-4 weeks', '4-6 weeks', '6+ weeks'] }, display_order: 5)
  puts "✅ Autism Evaluations - 5 fields added"
end

# Speech Therapy
puts "Adding Speech Therapy fields..."
speech = ProviderCategory.find_by(slug: 'speech_therapy')
if speech
  speech.category_fields.create!(name: 'Specialties', field_type: 'multi_select', required: true, options: { choices: ['Articulation', 'Language Development', 'Fluency/Stuttering', 'Voice Disorders', 'Swallowing Disorders', 'Social Communication'] }, display_order: 1)
  speech.category_fields.create!(name: 'Credentials', field_type: 'select', required: true, options: { choices: ['Speech-Language Pathologist (SLP)', 'Licensed SLP', 'ASHA Certified', 'Clinical Fellow', 'Specialist Certification'] }, display_order: 2)
  speech.category_fields.create!(name: 'Age Range Served', field_type: 'select', required: true, options: { choices: ['0-3 (Early Intervention)', '3-5 (Preschool)', '5-12 (School Age)', '12-18 (Adolescent)', '18+ (Adult)', 'All Ages'] }, display_order: 3)
  speech.category_fields.create!(name: 'Insurance Accepted', field_type: 'select', required: false, options: { choices: ['Medicaid', 'Private Insurance', 'Self-Pay', 'Sliding Scale', 'School District Contracts'] }, display_order: 4)
  speech.category_fields.create!(name: 'Teletherapy', field_type: 'boolean', required: false, options: {}, help_text: 'Available for online sessions')
  puts "✅ Speech Therapy - 5 fields added"
end

puts "✅ Fields added successfully!"
puts "Total categories: #{ProviderCategory.count}"
puts "Total fields: #{CategoryField.count}" 