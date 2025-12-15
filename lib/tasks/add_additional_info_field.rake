namespace :educational_programs do
  desc "Add Additional Information field to Educational Programs category"
  task add_additional_info_field: :environment do
    puts "📝 Adding Additional Information field to Educational Programs category..."
    
    category = ProviderCategory.find_by(slug: 'educational_programs')
    
    unless category
      puts "❌ Error: Educational Programs category not found!"
      exit 1
    end
    
    puts "✅ Found category: #{category.name}"
    
    existing_field = category.category_fields.find_by(name: 'Additional Information')
    
    if existing_field
      puts "⚠️  Field 'Additional Information' already exists. Updating..."
      existing_field.update!(
        field_type: 'textarea',
        required: false,
        display_order: 8,
        help_text: 'Any additional information about the educational program',
        slug: 'additional_information',
        is_active: true
      )
      puts "✅ Updated field: Additional Information"
    else
      max_order = category.category_fields.maximum(:display_order) || 0
      
      field = category.category_fields.create!(
        name: 'Additional Information',
        slug: 'additional_information',
        field_type: 'textarea',
        required: false,
        display_order: max_order + 1,
        help_text: 'Any additional information about the educational program',
        is_active: true,
        options: {}
      )
      
      puts "✅ Created field: Additional Information (textarea)"
      puts "   Display order: #{field.display_order}"
      puts "   Slug: #{field.slug}"
    end
    
    puts ""
    puts "🎉 Additional Information field added successfully!"
    puts "📊 Total fields for Educational Programs: #{category.category_fields.count}"
  end
end
