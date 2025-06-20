class PracticeType < ApplicationRecord
  has_many :provider_practice_types, dependent: :destroy
  has_many :providers, through: :provider_practice_types

  has_many :locations_practice_types, dependent: :destroy
  has_many :locations, through: :locations_practice_types

  validates :name, presence: true, uniqueness: true
end
