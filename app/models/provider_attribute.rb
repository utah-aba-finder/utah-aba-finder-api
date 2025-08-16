class ProviderAttribute < ApplicationRecord
  belongs_to :provider
  belongs_to :category_field
  
  validates :provider_id, uniqueness: { scope: :category_field_id }
  validates :value, presence: true, if: :required_field?
  
  scope :for_category, ->(category) { joins(:category_field).where(category_fields: { provider_category: { slug: category } }) }
  
  def required_field?
    category_field&.required?
  end
  
  def display_value
    case category_field.field_type
    when 'boolean'
      value == 'true' ? 'Yes' : 'No'
    when 'checkbox'
      value == 'true' ? 'Available' : 'Not Available'
    else
      value
    end
  end
  
  def field_name
    category_field.name
  end
  
  def field_type
    category_field.field_type
  end
  
  def required?
    category_field.required?
  end
end 