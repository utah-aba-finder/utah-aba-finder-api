class Insurance < ApplicationRecord
  has_many :provider_insurances, dependent: :destroy
  has_many :providers, through: :provider_insurances
end
