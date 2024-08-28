class Insurance < ApplicationRecord
  has_many :provider_insurances
  has_many :providers, through: :provider_insurances
end
