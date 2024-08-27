class Provider < ApplicationRecord

  has_many :counties
  has_many :locations
  has_many :providers_insurance
  has_many :insurances, through: :providers_insurance
end
