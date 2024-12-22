class County < ApplicationRecord
  belongs_to :state
  has_and_belongs_to_many :providers

  validates :name, presence: true, uniqueness: { scope: :state_id }
end