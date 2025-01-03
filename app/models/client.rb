class Client < ApplicationRecord
  before_validation :generate_api_key, on: :create

  validates :name, presence: true, uniqueness: true
  validates :api_key, presence: true, uniqueness: true

  private

  def generate_api_key
    self.api_key ||= SecureRandom.hex
  end
end