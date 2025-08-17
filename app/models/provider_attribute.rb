class ProviderAttribute < ApplicationRecord
  belongs_to :provider
  belongs_to :category_field

  validates :provider_id, uniqueness: { scope: :category_field_id }


  def display_value
    case category_field.field_type
    when 'boolean'
      value == 'true' ? 'Yes' : 'No'
    when 'multi_select'
      value.present? ? value.split(', ').join(', ') : 'None'
    else
      value.presence || 'Not specified'
    end
  end

  def field_name
    category_field.name
  end

  def field_type
    category_field.field_type
  end

  def required?
    category_field.required
  end

  def to_s
    "#{field_name}: #{display_value}"
  end
end 