require 'rails_helper'

RSpec.describe Client, type: :model do
  before do
    @existing_client = Client.create(name: "UniqueName", api_key: "unique_api_key")
  end
  
  describe 'validations' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :api_key }
    it { should validate_uniqueness_of :name }
    it { should validate_uniqueness_of :api_key }
  end
end
