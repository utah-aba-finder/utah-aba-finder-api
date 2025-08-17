class ProviderCategory < ApplicationRecord
  has_many :category_fields, dependent: :destroy
  has_many :providers, foreign_key: 'category', primary_key: 'slug'

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }

  before_validation :generate_slug, if: :name_changed?

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:display_order, :name) }

  def generate_slug
    self.slug = name.parameterize.underscore if name.present?
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

  def to_s
    name
  end
end 