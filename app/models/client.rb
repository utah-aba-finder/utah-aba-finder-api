class Client < ApplicationRecord
  before_create :generate_api_key

  private

  def generate_api_key
    self.api_key = SecureRandom.hex
  end
end