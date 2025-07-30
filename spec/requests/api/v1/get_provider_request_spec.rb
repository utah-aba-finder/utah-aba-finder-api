require "rails_helper"

RSpec.describe "Get Provider Request", type: :request do
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
      logo: "https://logo.com",
      in_home_only: false,
      service_delivery: { in_home: false, in_clinic: false, telehealth: false }
      )
      
    @insurance1 = Insurance.create!(name: "Insurance A")
    @insurance2 = Insurance.create!(name: "Insurance B")

    @pi1 = ProviderInsurance.create!(provider: @provider, insurance: @insurance1, accepted: true)
    @pi2 = ProviderInsurance.create!(provider: @provider, insurance: @insurance2, accepted: false)

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

    OldCounty.create!(provider: @provider, counties_served: "Salt Lake, Davis")

    @client = Client.create!(name: "test_client", api_key: SecureRandom.hex)
    @api_key = @client.api_key
  end

  context "get /api/v1/providers/:id" do
    it "returns provider with provider attributes" do
      get "/api/v1/providers/#{@provider.id}", headers: { 'Content-Type': 'application/json', 'Authorization': @api_key, 'Accept': 'application/json' }

      expect(response).to be_successful
      expect(response.status).to eq(200)

      provider_response = JSON.parse(response.body, symbolize_names: true)

      expect(provider_response).to be_an(Hash)

      expect(provider_response).to have_key(:data)
      expect(provider_response[:data]).to be_a(Array)
      expect(provider_response[:data].size).to eq(1)

      expect(provider_response[:data].first).to have_key(:id)
      expect(provider_response[:data].first[:id]).to eq(@provider.id)

      expect(provider_response[:data].first[:attributes]).to have_key(:name)
      expect(provider_response[:data].first[:attributes][:name]).to be_a(String)

      expect(provider_response[:data].first[:attributes]).to have_key(:website)
      expect(provider_response[:data].first[:attributes][:website]).to be_a(String)

      expect(provider_response[:data].first[:attributes]).to have_key(:email)
      expect(provider_response[:data].first[:attributes][:email]).to be_a(String)

      expect(provider_response[:data].first[:attributes]).to have_key(:cost)
      expect(provider_response[:data].first[:attributes][:cost]).to be_a(String)

      expect(provider_response[:data].first[:attributes]).to have_key(:min_age)
      expect(provider_response[:data].first[:attributes][:min_age]).to be_a(Float)

      expect(provider_response[:data].first[:attributes]).to have_key(:max_age)
      expect(provider_response[:data].first[:attributes][:max_age]).to be_a(Float)

      expect(provider_response[:data].first[:attributes]).to have_key(:waitlist)
      expect(provider_response[:data].first[:attributes][:waitlist]).to be_a(String)

      expect(provider_response[:data].first[:attributes]).to have_key(:telehealth_services)
      expect(provider_response[:data].first[:attributes][:telehealth_services]).to be_a(String)

      expect(provider_response[:data].first[:attributes]).to have_key(:at_home_services)
      expect(provider_response[:data].first[:attributes][:at_home_services]).to be_a(String)

      expect(provider_response[:data].first[:attributes]).to have_key(:in_clinic_services)
      expect(provider_response[:data].first[:attributes][:in_clinic_services]).to be_a(String)

      expect(provider_response[:data].first[:attributes]).to have_key(:spanish_speakers)
      expect(provider_response[:data].first[:attributes][:spanish_speakers]).to be_a(String)

      expect(provider_response[:data].first[:attributes]).to have_key(:logo)
      expect(provider_response[:data].first[:attributes][:logo]).to be_a(String)

      expect(provider_response[:data].first[:attributes]).to have_key(:insurance)
      expect(provider_response[:data].first[:attributes][:insurance]).to be_a(Array)
      
      provider_response[:data].first[:attributes][:insurance].each do |insurance|
        expect(insurance).to have_key(:name)
        expect(insurance[:name]).to be_a(String)
        expect(insurance).to have_key(:accepted)
        expect(insurance[:accepted]).to be(true)
        expect(insurance).to have_key(:id)
        expect(insurance[:id]).to be_an(Integer)
      end

      expect(provider_response[:data].first[:attributes]).to have_key(:locations)
      expect(provider_response[:data].first[:attributes][:locations]).to be_a(Array)

      provider_response[:data].first[:attributes][:locations].each do |location|
        expect(location).to be_a(Hash)
        expect(location).to have_key(:name)
        expect(location[:name]).to be_a(String)
        expect(location).to have_key(:id)
        expect(location[:id]).to be_an(Integer)
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

      expect(provider_response[:data].first[:attributes]).to have_key(:counties_served)
      expect(provider_response[:data].first[:attributes][:counties_served]).to be_a(Array)

      provider_response[:data].first[:attributes][:counties_served].each do |area_served|
        expect(area_served).to be_a(Hash)
        expect(area_served).to have_key(:county)
        expect(area_served[:county]).to be_a(String)
      end
    end

    it "it throws error if not authorized with bearer token" do

      get "/api/v1/providers/#{@provider.id}"

      expect(response.status).to eq(401)

      error_response = JSON.parse(response.body, symbolize_names: true)

      expect(error_response).to be_an(Hash)
      expect(error_response).to have_key(:error)
      expect(error_response[:error]).to eq("Unauthorized")
    end
  end
end