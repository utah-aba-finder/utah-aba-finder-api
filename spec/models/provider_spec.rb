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
        logo: "https://logo.com",
        in_home_only: false,
        service_delivery: { 'in_home' => true, 'in_clinic' => true, 'telehealth' => true },
        service_area: { 'states_served' => ['UT'], 'counties_served' => [] }
        )

      # Create locations after provider creation to satisfy validation
      provider.locations.create!(
        name: "Location 1",
        address_1: "123 Main St",
        address_2: "Suite 100",
        city: "Salt Lake City",
        state: "UT",
        zip: "84101",
        phone: "555-1234",
        email: "location1@provider1.com"
      )

      provider.locations.create!(
        name: "Location 2",
        address_1: "123 Not Main St",
        address_2: "Suite 101",
        city: "Salt Lake City",
        state: "UT",
        zip: "84101",
        phone: "555-4321",
        email: "location2@provider1.com"
      )

      location_params = [
        {
          id: provider.locations[0].id,
          name: "Update Name",
          address_1: "Updated Address",
          address_2: "Updated Address 2",
          city: "Salt Lake City",
          state: "UT",
          zip: "84101",
          phone: "111-1111",
          email: "location1@provider1.com"
        },
        {
          id: provider.locations[1].id,
          name: "Update Name 2",
          address_1: "Updated Address 2",
          address_2: "Updated Address 2 2",
          city: "Salt Lake City",
          state: "UT",
          zip: "84101",
          phone: "222-2222",
          email: "location2@provider1.com"
        },
        {
          # No id provided for this new location, meaning it should be created
          name: "New Location",
          address_1: "789 New St",
          address_2: "Suite 102",
          city: "Salt Lake City",
          state: "UT",
          zip: "84102",
          phone: "333-3333",
          email: "newlocation@provider1.com"
        }
      ]

      provider.update_locations(location_params)
      provider.reload

      expect(provider.locations[0].name).to eq("Update Name")
      expect(provider.locations[0].address_1).to eq("Updated Address")
      expect(provider.locations[0].address_2).to eq("Updated Address 2")
      expect(provider.locations[0].city).to eq("Salt Lake City")
      expect(provider.locations[0].state).to eq("UT")
      expect(provider.locations[0].zip).to eq("84101")
      expect(provider.locations[0].phone).to eq("111-1111")
      expect(provider.locations[0].email).to eq("location1@provider1.com")

      expect(provider.locations[1].name).to eq("Update Name 2")
      expect(provider.locations[1].address_1).to eq("Updated Address 2")
      expect(provider.locations[1].address_2).to eq("Updated Address 2 2")
      expect(provider.locations[1].city).to eq("Salt Lake City")
      expect(provider.locations[1].state).to eq("UT")
      expect(provider.locations[1].zip).to eq("84101")
      expect(provider.locations[1].phone).to eq("222-2222")
      expect(provider.locations[1].email).to eq("location2@provider1.com")
      # Validate new location creation
      new_location = provider.locations.last
      expect(new_location.name).to eq("New Location")
      expect(new_location.address_1).to eq("789 New St")
      expect(new_location.address_2).to eq("Suite 102")
      expect(new_location.city).to eq("Salt Lake City")
      expect(new_location.state).to eq("UT")
      expect(new_location.zip).to eq("84102")
      expect(new_location.phone).to eq("333-3333")
      expect(new_location.email).to eq("newlocation@provider1.com")
    end
  end
end