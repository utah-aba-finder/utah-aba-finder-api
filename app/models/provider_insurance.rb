class ProviderInsurance < ApplicationRecord
  belongs_to :provider
  belongs_to :insurance
end
