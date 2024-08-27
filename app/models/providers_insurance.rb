class ProvidersInsurance < ApplicationRecord
  belongs_to :provider
  belongs_to :insurance
end
