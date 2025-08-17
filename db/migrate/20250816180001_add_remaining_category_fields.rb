class AddRemainingCategoryFields < ActiveRecord::Migration[7.1]
  def up
    puts "🚀 Adding remaining category fields..."
    
    # Occupational Therapy
    puts "🏥 Adding Occupational Therapy fields..."
    ot = ProviderCategory.find_by(slug: 'occupational_therapy')
    if ot
      ot.category_fields.create!(
        name: 'Specialties', 
        field_type: 'multi_select', 
        required: true, 
        options: { 'choices' => ['Pediatric OT', 'Sensory Integration', 'Fine Motor Skills', 'Gross Motor Skills', 'ADL Training', 'Hand Therapy'] }, 
        display_order: 1
      )
      ot.category_fields.create!(
        name: 'Credentials', 
        field_type: 'select', 
        required: true, 
        options: { 'choices' => ['Occupational Therapist (OT)', 'Licensed OT', 'NBCOT Certified', 'Specialist Certification', 'Advanced Practice'] }, 
        display_order: 2
      )
      ot.category_fields.create!(
        name: 'Age Range Served', 
        field_type: 'select', 
        required: true, 
        options: { 'choices' => ['0-3 (Early Intervention)', '3-5 (Preschool)', '5-12 (School Age)', '12-18 (Adolescent)', '18+ (Adult)', 'All Ages'] }, 
        display_order: 3
      )
      ot.category_fields.create!(
        name: 'Insurance Accepted', 
        field_type: 'select', 
        required: false, 
        options: { 'choices' => ['Medicaid', 'Private Insurance', 'Self-Pay', 'Sliding Scale', 'School District Contracts'] }, 
        display_order: 4
      )
      ot.category_fields.create!(
        name: 'Home Visits', 
        field_type: 'boolean', 
        required: false, 
        options: {}, 
        help_text: 'Provides in-home occupational therapy'
      )
      puts "✅ Occupational Therapy - 5 fields added"
    end

    # Coaching/Mentoring
    puts "🎯 Adding Coaching/Mentoring fields..."
    coaching = ProviderCategory.find_by(slug: 'coaching_mentoring')
    if coaching
      coaching.category_fields.create!(
        name: 'Specialties', 
        field_type: 'multi_select', 
        required: true, 
        options: { 'choices' => ['Life Coaching', 'Career Coaching', 'Parent Coaching', 'Executive Coaching', 'Wellness Coaching', 'Academic Coaching'] }, 
        display_order: 1
      )
      coaching.category_fields.create!(
        name: 'Credentials', 
        field_type: 'select', 
        required: true, 
        options: { 'choices' => ['Certified Life Coach', 'Professional Coach', 'Licensed Therapist', 'Certified Parent Coach', 'Executive Coach', 'Wellness Coach'] }, 
        display_order: 2
      )
      coaching.category_fields.create!(
        name: 'Age Range Served', 
        field_type: 'select', 
        required: true, 
        options: { 'choices' => ['Children (5-12)', 'Teens (13-18)', 'Young Adults (18-25)', 'Adults (25+)', 'All Ages'] }, 
        display_order: 3
      )
      coaching.category_fields.create!(
        name: 'Insurance Accepted', 
        field_type: 'select', 
        required: false, 
        options: { 'choices' => ['Private Insurance', 'Self-Pay', 'Sliding Scale', 'Employee Benefits', 'Not Applicable'] }, 
        display_order: 4
      )
      coaching.category_fields.create!(
        name: 'Session Types', 
        field_type: 'multi_select', 
        required: false, 
        options: { 'choices' => ['Individual Sessions', 'Group Sessions', 'Family Sessions', 'Online/Video', 'Phone Sessions'] }, 
        display_order: 5
      )
      puts "✅ Coaching/Mentoring - 5 fields added"
    end

    # Pediatricians
    puts "👶 Adding Pediatricians fields..."
    pediatricians = ProviderCategory.find_by(slug: 'pediatricians')
    if pediatricians
      pediatricians.category_fields.create!(
        name: 'Specialties', 
        field_type: 'multi_select', 
        required: true, 
        options: { 'choices' => ['General Pediatrics', 'Developmental Pediatrics', 'Behavioral Pediatrics', 'Adolescent Medicine', 'Special Needs Pediatrics'] }, 
        display_order: 1
      )
      pediatricians.category_fields.create!(
        name: 'Insurance Accepted', 
        field_type: 'select', 
        required: false, 
        options: { 'choices' => ['Medicaid', 'Private Insurance', 'CHIP', 'Self-Pay', 'Sliding Scale'] }, 
        display_order: 2
      )
      pediatricians.category_fields.create!(
        name: 'Emergency Services', 
        field_type: 'boolean', 
        required: false, 
        options: {}, 
        help_text: 'Available for urgent care needs'
      )
      pediatricians.category_fields.create!(
        name: 'Special Needs Experience', 
        field_type: 'boolean', 
        required: false, 
        options: {}, 
        help_text: 'Experience with special needs patients'
      )
      pediatricians.category_fields.create!(
        name: 'Languages', 
        field_type: 'multi_select', 
        required: false, 
        options: { 'choices' => ['English', 'Spanish', 'ASL', 'Other'] }
      )
      puts "✅ Pediatricians - 5 fields added"
    end

    # Orthodontists
    puts "🦷 Adding Orthodontists fields..."
    orthodontists = ProviderCategory.find_by(slug: 'orthodontists')
    if orthodontists
      orthodontists.category_fields.create!(
        name: 'Specialties', 
        field_type: 'multi_select', 
        required: true, 
        options: { 'choices' => ['Traditional Braces', 'Clear Aligners', 'Early Intervention', 'Adult Orthodontics', 'Surgical Orthodontics'] }, 
        display_order: 1
      )
      orthodontists.category_fields.create!(
        name: 'Insurance Accepted', 
        field_type: 'select', 
        required: false, 
        options: { 'choices' => ['Delta Dental', 'MetLife', 'Aetna', 'Cigna', 'Self-Pay', 'Payment Plans'] }, 
        display_order: 2
      )
      orthodontists.category_fields.create!(
        name: 'Emergency Services', 
        field_type: 'boolean', 
        required: false, 
        options: {}, 
        help_text: 'Available for urgent orthodontic needs'
      )
      orthodontists.category_fields.create!(
        name: 'Special Needs Experience', 
        field_type: 'boolean', 
        required: false, 
        options: {}, 
        help_text: 'Experience with special needs patients'
      )
      orthodontists.category_fields.create!(
        name: 'Payment Plans', 
        field_type: 'boolean', 
        required: false, 
        options: {}, 
        help_text: 'Offers flexible payment options'
      )
      puts "✅ Orthodontists - 5 fields added"
    end

    puts "🎉 ALL REMAINING FIELDS ADDED SUCCESSFULLY!"
    puts "Total categories: #{ProviderCategory.count}"
    puts "Total fields: #{CategoryField.count}"
  end

  def down
    # Remove all the fields we added
    CategoryField.where(name: [
      'Specialties', 'Home Visits', 'Session Types', 'Emergency Services', 
      'Special Needs Experience', 'Languages', 'Payment Plans'
    ]).destroy_all
  end
end 