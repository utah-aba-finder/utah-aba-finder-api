require 'rails_helper'

RSpec.describe Client, type: :model do
  before do
    @existing_client = create(:client, name: "UniqueName", api_key: "unique_api_key")
  end

  describe 'validations' do
    it { should validate_presence_of :name }

    it 'validates presence of api_key' do
      allow_any_instance_of(Client).to receive(:generate_api_key)
      client = build(:client, name: 'NewClient', api_key: nil)
      expect(client).to_not be_valid
      expect(client.errors[:api_key]).to include("can't be blank")
    end
    
    it { should validate_uniqueness_of :name }
    it { should validate_uniqueness_of :api_key }
  end
end
