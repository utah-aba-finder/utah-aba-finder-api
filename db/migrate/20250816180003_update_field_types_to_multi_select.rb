class UpdateFieldTypesToMultiSelect < ActiveRecord::Migration[7.1]
  def up
    puts "🔄 Updating field types to support multiple selections..."
    
    # Update ABA Therapy fields
    update_field_type('aba_therapy', 'Specialties', 'multi_select')
    update_field_type('aba_therapy', 'Certifications', 'multi_select')
    update_field_type('aba_therapy', 'Age Groups', 'multi_select')
    update_field_type('aba_therapy', 'Insurance Accepted', 'multi_select')
    
    # Update Autism Evaluations fields
    update_field_type('autism_evaluations', 'Credentials', 'multi_select')
    update_field_type('autism_evaluations', 'Age Range Served', 'multi_select')
    update_field_type('autism_evaluations', 'Insurance Accepted', 'multi_select')
    
    # Update Speech Therapy fields
    update_field_type('speech_therapy', 'Certifications', 'multi_select')
    update_field_type('speech_therapy', 'Age Groups', 'multi_select')
    update_field_type('speech_therapy', 'Insurance Accepted', 'multi_select')
    
    # Update Occupational Therapy fields
    update_field_type('occupational_therapy', 'Certifications', 'multi_select')
    update_field_type('occupational_therapy', 'Age Groups', 'multi_select')
    update_field_type('occupational_therapy', 'Insurance Accepted', 'multi_select')
    
    # Update Coaching/Mentoring fields
    update_field_type('coaching_mentoring', 'Credentials', 'multi_select')
    update_field_type('coaching_mentoring', 'Age Groups', 'multi_select')
    update_field_type('coaching_mentoring', 'Session Format', 'multi_select')
    
    # Update Pediatricians fields
    update_field_type('pediatricians', 'Board Certifications', 'multi_select')
    update_field_type('pediatricians', 'Age Range', 'multi_select')
    update_field_type('pediatricians', 'Insurance Accepted', 'multi_select')
    
    # Update Orthodontists fields
    update_field_type('orthodontists', 'Certifications', 'multi_select')
    update_field_type('orthodontists', 'Age Groups', 'multi_select')
    update_field_type('orthodontists', 'Insurance Accepted', 'multi_select')
    
    # Update Dentists fields
    update_field_type('dentists', 'Certifications', 'multi_select')
    update_field_type('dentists', 'Age Groups', 'multi_select')
    update_field_type('dentists', 'Insurance Accepted', 'multi_select')
    
    # Update Physical Therapists fields
    update_field_type('physical_therapists', 'Certifications', 'multi_select')
    update_field_type('physical_therapists', 'Age Groups', 'multi_select')
    update_field_type('physical_therapists', 'Insurance Accepted', 'multi_select')
    
    # Update Barbers/Hair fields
    update_field_type('barbers_hair', 'Experience', 'multi_select')
    update_field_type('barbers_hair', 'Age Groups', 'multi_select')
    update_field_type('barbers_hair', 'Pricing', 'multi_select')
    
    # Update Advocates fields
    update_field_type('advocates', 'Credentials', 'multi_select')
    update_field_type('advocates', 'Age Groups', 'multi_select')
    update_field_type('advocates', 'Services', 'multi_select')
    
    # Update Therapists fields
    update_field_type('therapists', 'Licenses', 'multi_select')
    update_field_type('therapists', 'Age Groups', 'multi_select')
    update_field_type('therapists', 'Insurance Accepted', 'multi_select')
    
    puts "✅ Field types updated successfully!"
  end

  def down
    puts "🔄 Rolling back field type changes..."
    
    # Revert all multi_select fields back to select
    CategoryField.where(field_type: 'multi_select').update_all(field_type: 'select')
    
    puts "✅ Field types reverted to single select"
  end

  private

  def update_field_type(category_slug, field_name, new_type)
    category = ProviderCategory.find_by(slug: category_slug)
    return unless category
    
    field = category.category_fields.find_by(name: field_name)
    if field
      field.update!(field_type: new_type)
      puts "✅ Updated #{category.name} - #{field_name} to #{new_type}"
    else
      puts "⚠️  Field not found: #{category.name} - #{field_name}"
    end
  end
end
