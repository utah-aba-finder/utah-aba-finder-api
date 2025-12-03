class ProviderView < ApplicationRecord
  belongs_to :provider

  validates :fingerprint, presence: true
  validates :view_date, presence: true

  # Ensure unique views per provider per fingerprint per day
  validates :fingerprint, uniqueness: { scope: [:provider_id, :view_date] }
end

