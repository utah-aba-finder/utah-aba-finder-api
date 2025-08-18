class ProviderCategorySerializer
  def self.format_categories(categories)
    {
      data: categories.map do |category|
        format_category(category)
      end
    }
  end

  def self.format_category(category)
    {
      id: category.id,
      type: "provider_category",
      attributes: {
        name: category.name,
        slug: category.slug,
        description: category.description,
        is_active: category.is_active,
        display_order: category.display_order,
        category_fields: category.category_fields.active.ordered.map do |field|
          {
            id: field.id,
            name: field.name,
            slug: field.slug || field.name.parameterize.underscore,
            field_type: field.field_type,
            required: field.required,
            options: field.options,
            display_order: field.display_order,
            help_text: field.help_text
          }
        end
      end
    }
  end
end
