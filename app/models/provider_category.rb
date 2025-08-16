class ProviderCategory < ApplicationRecord
  has_many :category_fields, dependent: :destroy
  has_many :providers
  
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_-]+\z/ }
  
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:display_order, :name) }
  
  before_validation :generate_slug, if: :name_changed?
  
  def to_param
    slug
  end
  
  def field_count
    category_fields.count
  end
  
  def required_fields
    category_fields.where(required: true).ordered
  end
  
  def optional_fields
    category_fields.where(required: false).ordered
  end
  
  private
  
  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end 