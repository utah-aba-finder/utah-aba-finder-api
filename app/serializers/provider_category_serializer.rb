class ProviderCategorySerializer
  def self.format_categories(categories)
    { data: categories.map { |c| format_category(c) } }
  end

  def self.format_category(category)
    {
      id: category.id.to_s,
      type: "provider_category",
      attributes: {
        name: category.name,
        slug: category.slug,
        description: category.description,
        is_active: category.is_active?,
        display_order: category.display_order,

        # ↓↓↓ This map block was missing its `end`
        category_fields: category.category_fields.active.ordered.map do |field|
          {
            id: field.id.to_s,
            name: field.name,
            # include slug if you have it; highly recommended for stable keys
            slug: (field.respond_to?(:slug) ? field.slug : nil),
            field_type: field.field_type,
            required: field.required,
            options: field.options || {},
            display_order: field.display_order,
            help_text: field.help_text
          }
        end # ← closes the `map do |field|`

      } # ← closes :attributes
    }   # ← closes outer category hash
  end
end
