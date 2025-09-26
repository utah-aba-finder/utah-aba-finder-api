class UpdateSlidingScaleToFlexiblePricing < ActiveRecord::Migration[7.1]
  def up
    puts "🔄 Updating 'Sliding Scale' to 'Flexible pricing based on your circumstances'..."
    
    # Update CategoryField options that contain "Sliding Scale"
    CategoryField.find_each do |field|
      if field.options.is_a?(Hash) && field.options['choices'].is_a?(Array)
        updated_choices = field.options['choices'].map do |choice|
          if choice == 'Sliding Scale'
            'Flexible pricing based on your circumstances'
          else
            choice
          end
        end
        
        if updated_choices != field.options['choices']
          field.update!(options: field.options.merge('choices' => updated_choices))
          puts "✅ Updated field '#{field.name}' in category '#{field.provider_category&.name}'"
        end
      end
    end
    
    # Update field names from "Sliding Scale" to "Flexible Pricing"
    CategoryField.where(name: 'Sliding Scale').find_each do |field|
      field.update!(
        name: 'Flexible Pricing',
        help_text: 'Pricing varies based on your specific situation and needs'
      )
      puts "✅ Updated field name to 'Flexible Pricing' in category '#{field.provider_category&.name}'"
    end
    
    # Update any existing provider attributes that have "Sliding Scale" values
    ProviderAttribute.joins(:category_field)
                    .where(category_fields: { name: 'Flexible Pricing' })
                    .where(value: 'Sliding Scale')
                    .update_all(value: 'Yes')
    
    puts "✅ Updated existing provider attributes"
    
    puts "🎉 Successfully updated all 'Sliding Scale' references!"
  end

  def down
    puts "🔄 Reverting 'Flexible pricing based on your circumstances' back to 'Sliding Scale'..."
    
    # Revert CategoryField options
    CategoryField.find_each do |field|
      if field.options.is_a?(Hash) && field.options['choices'].is_a?(Array)
        updated_choices = field.options['choices'].map do |choice|
          if choice == 'Flexible pricing based on your circumstances'
            'Sliding Scale'
          else
            choice
          end
        end
        
        if updated_choices != field.options['choices']
          field.update!(options: field.options.merge('choices' => updated_choices))
        end
      end
    end
    
    # Revert field names
    CategoryField.where(name: 'Flexible Pricing').find_each do |field|
      field.update!(
        name: 'Sliding Scale',
        help_text: 'Income-based pricing available'
      )
    end
    
    # Revert provider attributes
    ProviderAttribute.joins(:category_field)
                    .where(category_fields: { name: 'Sliding Scale' })
                    .where(value: 'Yes')
                    .update_all(value: 'Sliding Scale')
    
    puts "✅ Reverted all changes"
  end
end