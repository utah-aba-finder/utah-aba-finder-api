class CategoryField < ApplicationRecord
  belongs_to :provider_category
  has_many :provider_attributes, dependent: :destroy

  validates :name, presence: true
  validates :field_type, presence: true, inclusion: { in: %w[text select multi_select boolean textarea] }
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:display_order, :name) }

  def text?
    field_type == 'text'
  end

  def select?
    field_type == 'select'
  end

  def multi_select?
    field_type == 'multi_select'
  end

  def boolean?
    field_type == 'boolean'
  end

  def textarea?
    field_type == 'textarea'
  end

  def choices
    options&.dig('choices') || []
  end

  def to_s
    name
  end
end 