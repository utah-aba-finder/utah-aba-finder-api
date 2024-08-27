class Insurance < ApplicationRecord
  has_many :providers_insurance
  has_many :providers, through: :providers_insurance
end
