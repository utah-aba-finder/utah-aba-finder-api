class CountiesProvider < ApplicationRecord
  belongs_to :provider
  belongs_to :county

  validates :provider_id, uniqueness: { scope: :county_id }
end