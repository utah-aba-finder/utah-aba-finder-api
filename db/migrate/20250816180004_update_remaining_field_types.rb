class UpdateRemainingFieldTypes < ActiveRecord::Migration[7.1]
  def up
    puts "🔄 Updating remaining field types to support multiple selections..."
    
    # Update fields based on actual names in database
    update_field_type('aba_therapy', 'Specialties', 'multi_select')
    update_field_type('aba_therapy', 'Certifications', 'multi_select')
    update_field_type('aba_therapy', 'Age Groups', 'multi_select')
    update_field_type('aba_therapy', 'Insurance Accepted', 'multi_select')
    
    update_field_type('autism_evaluations', 'Credentials', 'multi_select')
    update_field_type('autism_evaluations', 'Age Range Served', 'multi_select')
    update_field_type('autism_evaluations', 'Insurance Accepted', 'multi_select')
    
    update_field_type('speech_therapy', 'Specialties', 'multi_select')
    update_field_type('speech_therapy', 'Credentials', 'multi_select')
    update_field_type('speech_therapy', 'Age Range Served', 'multi_select')
    update_field_type('speech_therapy', 'Insurance Accepted', 'multi_select')
    
    update_field_type('occupational_therapy', 'Specialties', 'multi_select')
    update_field_type('occupational_therapy', 'Credentials', 'multi_select')
    update_field_type('occupational_therapy', 'Age Range Served', 'multi_select')
    update_field_type('occupational_therapy', 'Insurance Accepted', 'multi_select')
    
    update_field_type('coaching_mentoring', 'Specialties', 'multi_select')
    update_field_type('coaching_mentoring', 'Age Range Served', 'multi_select')
    update_field_type('coaching_mentoring', 'Insurance Accepted', 'multi_select')
    update_field_type('coaching_mentoring', 'Session Types', 'multi_select')
    update_field_type('coaching_mentoring', 'Credentials', 'multi_select')
    
    update_field_type('pediatricians', 'Specialties', 'multi_select')
    update_field_type('pediatricians', 'Insurance Accepted', 'multi_select')
    
    update_field_type('orthodontists', 'Specialties', 'multi_select')
    update_field_type('orthodontists', 'Insurance Accepted', 'multi_select')
    
    update_field_type('dentists', 'Specialties', 'multi_select')
    update_field_type('dentists', 'Insurance Accepted', 'multi_select')
    
    update_field_type('physical_therapists', 'Specialties', 'multi_select')
    update_field_type('physical_therapists', 'Insurance Accepted', 'multi_select')
    
    update_field_type('barbers_hair', 'Services', 'multi_select')
    update_field_type('barbers_hair', 'Payment Methods', 'multi_select')
    
    update_field_type('advocates', 'Specialties', 'multi_select')
    update_field_type('advocates', 'Services', 'multi_select')
    
    update_field_type('therapists', 'Therapy Types', 'multi_select')
    update_field_type('therapists', 'Specialties', 'multi_select')
    update_field_type('therapists', 'Licenses', 'multi_select')
    
    puts "✅ Remaining field types updated successfully!"
  end

  def down
    puts "🔄 Rolling back remaining field type changes..."
    
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
