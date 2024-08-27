class Insurance < ApplicationRecord
  has_many :providers_insurances
  has_many :providers, through: :providers_insurances
end
