class ProviderCounty < ApplicationRecord
  belongs_to :provider
  belongs_to :county
end