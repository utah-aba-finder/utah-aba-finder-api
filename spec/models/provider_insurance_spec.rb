require 'rails_helper'

RSpec.describe ProviderInsurance, type: :model do

  describe 'relationships' do
    it { should belong_to(:provider) }
    it { should belong_to(:insurance) }
  end

  describe '#initialize_provider_insurances' do
    it 'creates a ProviderInsurance record with accepted: false for each insurance' do
      insurance1 = Insurance.create!(name: "Insurance A")
      insurance2 = Insurance.create!(name: "Insurance B")
      insurance3 = Insurance.create!(name: "Insurance C")

      provider = Provider.create!(name: "Test Provider")

      expect(ProviderInsurance.count).to eq(0)

      provider.initialize_provider_insurances

      expect(ProviderInsurance.count).to eq(3)

      ProviderInsurance.all.each do |provider_insurance|
        expect(provider_insurance.provider_id).to eq(provider.id)
        expect(provider_insurance.accepted).to be_false
      end
    end
  end
end