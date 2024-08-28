class Provider < ApplicationRecord

  has_many :counties
  has_many :locations
  has_many :provider_insurances
  has_many :insurances, through: :provider_insurances
end
