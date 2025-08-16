class CategoryField < ApplicationRecord
  belongs_to :provider_category
  has_many :provider_attributes, dependent: :destroy
  
  validates :name, presence: true
  validates :field_type, presence: true, inclusion: { in: %w[text textarea select checkbox radio boolean] }
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:display_order, :name) }
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  
  def text_field?
    %w[text textarea].include?(field_type)
  end
  
  def select_field?
    %w[select checkbox radio].include?(field_type)
  end
  
  def boolean_field?
    field_type == 'boolean'
  end
  
  def has_options?
    select_field? && options['choices'].present?
  end
  
  def choice_options
    options['choices'] || []
  end
  
  def help_text_or_default
    help_text.presence || "Enter #{name.downcase}"
  end
end 