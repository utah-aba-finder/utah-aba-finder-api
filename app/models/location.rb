class Location < ApplicationRecord
  belongs_to :provider
  has_many :locations_practice_types, dependent: :destroy
  has_many :practice_types, through: :locations_practice_types
end
