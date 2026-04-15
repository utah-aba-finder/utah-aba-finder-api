class PracticeType < ApplicationRecord
  has_many :provider_practice_types, dependent: :destroy
  has_many :providers, through: :provider_practice_types

  has_many :locations_practice_types, dependent: :destroy
  has_many :locations, through: :locations_practice_types

  # Display names we always normalize (case / minor spelling variants → single list label)
  CANONICAL_BY_DOWNCASE = {
    "aba therapy" => "ABA Therapy"
  }.freeze

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_validation :apply_canonical_display_name

  def self.canonical_display_name(name_like)
    return name_like if name_like.blank?

    s = name_like.to_s.strip
    CANONICAL_BY_DOWNCASE[s.downcase] || s
  end

  # Case-insensitive match; use for API/admin payloads that may use "Aba therapy", etc.
  def self.find_for_name(name)
    return nil if name.blank?

    canonical = canonical_display_name(name)
    where("LOWER(TRIM(name)) = ?", canonical.downcase).first
  end

  private

  def apply_canonical_display_name
    self.name = self.class.canonical_display_name(name) if name.present?
  end
end
