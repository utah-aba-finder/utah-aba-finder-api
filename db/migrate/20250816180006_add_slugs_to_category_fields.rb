class AddSlugsToCategoryFields < ActiveRecord::Migration[7.1]
  def up
    puts "🔄 Adding slugs to category fields..."
    
    add_column :category_fields, :slug, :string
    
    # Generate slugs for existing fields
    CategoryField.find_each do |field|
      slug = field.name.parameterize.underscore
      field.update!(slug: slug)
      puts "✅ Added slug '#{slug}' to #{field.name}"
    end
    
    # Make slug not null and add index
    change_column_null :category_fields, :slug, false
    add_index :category_fields, :slug
    
    puts "✅ Slugs added successfully!"
  end

  def down
    puts "🔄 Rolling back slug changes..."
    remove_index :category_fields, :slug
    remove_column :category_fields, :slug
    puts "✅ Slugs removed"
  end
end
