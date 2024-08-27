class Provider < ApplicationRecord
  
  has_many :counties
  has_many :locations
  has_many :providers_insurances
  has_many :insurances, through: :providers_insurances
end
