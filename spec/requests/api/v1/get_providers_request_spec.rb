require "rails_helper"

RSpec.describe "Get Providers Request", type: :request do
  before(:each) do
    @provider = Provider.create!(
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
      
    @insurance1 = Insurance.create!(name: "Insurance A")
    @insurance2 = Insurance.create!(name: "Insurance B")

    @pi1 = ProviderInsurance.create!(provider: @provider, insurance: @insurance1)
    @pi2 = ProviderInsurance.create!(provider: @provider, insurance: @insurance2)

    Location.create!(
      provider: @provider,
      name: "Location 1",
      address_1: "123 Main St",
      address_2: "Suite 100",
      city: "Salt Lake City",
      state: "UT",
      zip: "84101",
      phone: "555-1234",
      email: "location1@provider1.com"
    )

    County.create!(provider: @provider, counties_served: "Salt Lake County")
    County.create!(provider: @provider, counties_served: "Davis County")
  end

  context "get /api/v1/providers" do
    it "returns all providers with provider attributes" do

      get "/api/v1/providers"

      expect(response).to be_successful
      expect(response.status).to eq(200)

      providers_response = JSON.parse(response.body, symbolize_names: true)

      expect(providers_response).to be_an(Hash)

      expect(providers_response).to have_key(:data)
      expect(providers_response[:data]).to be_a(Array)
      expect(providers_response[:data].size).to eq(1)

      expect(providers_response[:data].first).to have_key(:id)
      expect(providers_response[:data].first[:id]).to eq(@provider.id)

      expect(providers_response[:data].first[:attributes]).to have_key(:name)
      expect(providers_response[:data].first[:attributes][:name]).to be_a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:website)
      expect(providers_response[:data].first[:attributes][:website]).to be_a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:email)
      expect(providers_response[:data].first[:attributes][:email]).to be_a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:cost)
      expect(providers_response[:data].first[:attributes][:cost]).to be_a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:min_age)
      expect(providers_response[:data].first[:attributes][:min_age]).to be_a(Float)

      expect(providers_response[:data].first[:attributes]).to have_key(:max_age)
      expect(providers_response[:data].first[:attributes][:max_age]).to be_a(Float)

      expect(providers_response[:data].first[:attributes]).to have_key(:waitlist)
      expect(providers_response[:data].first[:attributes][:waitlist]).to be_a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:telehealth_services)
      expect(providers_response[:data].first[:attributes][:telehealth_services]).to be_a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:at_home_services)
      expect(providers_response[:data].first[:attributes][:at_home_services]).to be_a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:in_clinic_services)
      expect(providers_response[:data].first[:attributes][:in_clinic_services]).to be_a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:spanish_speakers)
      expect(providers_response[:data].first[:attributes][:spanish_speakers]).to be_a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:logo)
      expect(providers_response[:data].first[:attributes][:logo]).to be_a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:insurance)
      expect(providers_response[:data].first[:attributes][:insurance]).to be_a(Array)
      
      providers_response[:data].first[:attributes][:insurance].each do |insurance|
        expect(insurance).to have_key(:name)
        expect(insurance[:name]).to be_a(String)
      end

      expect(providers_response[:data].first[:attributes]).to have_key(:locations)
      expect(providers_response[:data].first[:attributes][:locations]).to be_a(Array)

      providers_response[:data].first[:attributes][:locations].each do |location|
        expect(location).to be_a(Hash)
        expect(location).to have_key(:name)
        expect(location[:name]).to be_a(String)
        expect(location).to have_key(:address_1)
        expect(location[:address_1]).to be_a(String)
        expect(location).to have_key(:address_2)
        expect(location[:address_2]).to be_a(String)
        expect(location).to have_key(:city)
        expect(location[:city]).to be_a(String)
        expect(location).to have_key(:state)
        expect(location[:state]).to be_a(String)
        expect(location).to have_key(:zip)
        expect(location[:zip]).to be_a(String)
        expect(location).to have_key(:phone)
        expect(location[:phone]).to be_a(String)
      end

      expect(providers_response[:data].first[:attributes]).to have_key(:counties_served)
      expect(providers_response[:data].first[:attributes][:counties_served]).to be_a(Array)

      providers_response[:data].first[:attributes][:counties_served].each do |area_served|
        expect(area_served).to be_a(Hash)
        expect(area_served).to have_key(:county)
        expect(area_served[:county]).to be_a(String)
      end
    end
  end
end