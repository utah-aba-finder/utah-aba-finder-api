class ProviderPracticeType < ApplicationRecord
  belongs_to :provider
  belongs_to :practice_type

  validates :provider_id, uniqueness: { scope: :practice_type_id }
end
