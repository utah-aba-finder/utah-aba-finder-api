class FinalizeMultiSelectFields < ActiveRecord::Migration[7.1]
  def up
    puts "🔄 Finalizing multi-select fields and insurance options..."
    
    # Update ABA Therapy fields
    update_field_type('aba_therapy', 'Specialties', 'multi_select')
    update_field_type('aba_therapy', 'Certifications', 'multi_select')
    update_field_type('aba_therapy', 'Age Groups', 'multi_select')
    update_field_type('aba_therapy', 'Insurance Accepted', 'multi_select')
    
    # Update Physical Therapists fields
    update_field_type('physical_therapists', 'Specialties', 'multi_select')
    update_field_type('physical_therapists', 'Equipment Available', 'multi_select')
    update_field_type('physical_therapists', 'Insurance Accepted', 'multi_select')
    
    # Update Barbers/Hair fields
    update_field_type('barbers_hair', 'Services', 'multi_select')
    update_field_type('barbers_hair', 'Payment Methods', 'multi_select')
    
    # Update Advocates fields
    update_field_type('advocates', 'Fee Structure', 'multi_select')
    update_field_type('advocates', 'Languages', 'multi_select')
    
    # Update Dentists fields
    update_field_type('dentists', 'Sedation Options', 'multi_select')
    
    # Update insurance fields to allow custom options
    update_insurance_field_options
    
    puts "✅ All field types updated successfully!"
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

  def update_insurance_field_options
    puts "🔄 Updating insurance fields to allow custom options..."
    
    # Update all insurance fields to have more comprehensive options
    insurance_fields = CategoryField.where("name LIKE ?", "%Insurance%")
    
    insurance_fields.each do |field|
      category = field.provider_category
      case category.slug
      when 'aba_therapy'
        field.update!(options: {
          'choices' => [
            'Medicaid', 'Medicare', 'Private Insurance', 'Self-Pay', 'Sliding Scale',
            'School District Contracts', 'Tricare', 'CHIP', 'Workers Comp', 'Auto Insurance'
          ],
          'allow_custom' => true
        })
      when 'physical_therapists'
        field.update!(options: {
          'choices' => [
            'Medicare', 'Medicaid', 'Private Insurance', 'Self-Pay', 'School District Contracts',
            'Tricare', 'CHIP', 'Workers Comp', 'Auto Insurance', 'Sliding Scale'
          ],
          'allow_custom' => true
        })
      when 'dentists'
        field.update!(options: {
          'choices' => [
            'Delta Dental', 'MetLife', 'Aetna', 'Cigna', 'Self-Pay', 'Payment Plans',
            'Medicaid', 'Medicare', 'Tricare', 'CHIP', 'Sliding Scale'
          ],
          'allow_custom' => true
        })
      when 'orthodontists'
        field.update!(options: {
          'choices' => [
            'Delta Dental', 'MetLife', 'Aetna', 'Cigna', 'Self-Pay', 'Payment Plans',
            'Medicaid', 'Medicare', 'Tricare', 'CHIP', 'Sliding Scale'
          ],
          'allow_custom' => true
        })
      when 'barbers_hair'
        field.update!(options: {
          'choices' => [
            'Cash', 'Credit Card', 'Insurance', 'Sliding Scale', 'Package Deals',
            'Family Discounts', 'Payment Plans'
          ],
          'allow_custom' => true
        })
      when 'advocates'
        field.update!(options: {
          'choices' => [
            'Free', 'Sliding Scale', 'Hourly Rate', 'Flat Fee', 'Pro Bono',
            'Insurance Accepted', 'Payment Plans', 'Consultation Fee'
          ],
          'allow_custom' => true
        })
      end
      
      puts "✅ Updated #{category.name} - #{field.name} with comprehensive options"
    end
  end
end
