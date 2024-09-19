require 'rails_helper'

RSpec.describe Provider, type: :model do

  describe 'relationships' do
    it { should have_many(:counties) }
    it { should have_many(:locations) }
    it { should have_many(:provider_insurances) }
    it { should have_many(:insurances).through(:provider_insurances) }
  end

  describe 'instance methods' do
    it "can update it's locations with locations params info" do
      provider = Provider.create!(
        name: "Provider 1",
        website: "https://provider1.com",
        email: "contact@provider1.com",
        cost: "$100",
        min_age: 5.0,
        max_age: 18.0,
        waitlist: "Yes",
        telehealth_services: "Available",
        at_home_services: "Available",
        in_clinic_services: "Available",
        spanish_speakers: "Yes",
        logo: "https://logo.com"
        )

      # add second location to verify functionality for 2 locations after success
      provider.locations.create!(
        provider: provider,
        name: "Location 1",
        address_1: "123 Main St",
        address_2: "Suite 100",
        city: "Salt Lake City",
        state: "UT",
        zip: "84101",
        phone: "555-1234",
        email: "location1@provider1.com"
      )

      location_params = [
        {
          location_id: provider.locations.first.id,
          name: "Update Name",
          address_1: "Updated Address",
          address_2: "Updated Address 2",
          city: "Salt Lake City",
          state: "UT",
          zip: "84101",
          phone: "111-1111",
          email: "location1@provider1.com"
        }
      ]

      provider.update_locations(location_params)

      expect(provider.locations[0].name).to eq("Update Name")
      expect(provider.locations[0].address_1).to eq("Updated Address")
      expect(provider.locations[0].address_2).to eq("Updated Address 2")
      expect(provider.locations[0].city).to eq("Salt Lake City")
      expect(provider.locations[0].state).to eq("UT")
      expect(provider.locations[0].zip).to eq("84101")
      expect(provider.locations[0].phone).to eq("111-1111")
      expect(provider.locations[0].email).to eq("location1@provider1.com")
    end
  end
end