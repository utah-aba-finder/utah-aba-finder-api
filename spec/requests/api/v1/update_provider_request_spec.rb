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

  context "patch /api/v1/providers/:id" do
    it "can update a provider" do
      updated_attributes = {
        "name": "Updated Provider",
        "email": "updated@provider1.com",
        "cost": "$200",
        "min_age": 6.0,
        "max_age": 20.0
      }
  
      patch "/api/v1/providers/#{@provider.id}", params: updated_attributes.to_json, headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }
  
      expect(response).to be_successful
      expect(response.status).to eq(200)
  
      provider_response = JSON.parse(response.body, symbolize_names: true)
  
      expect(provider_response).to be_an(Hash)
      
      provider_data = provider_response[:data].first
  
      expect(provider_data).to have_key(:id)
      expect(provider_data[:id]).to eq(@provider.id)
  
      expect(provider_data[:attributes]).to have_key(:name)
      expect(provider_data[:attributes][:name]).to eq("Updated Provider")
  
      expect(provider_data[:attributes]).to have_key(:email)
      expect(provider_data[:attributes][:email]).to eq("updated@provider1.com")
  
      expect(provider_data[:attributes]).to have_key(:cost)
      expect(provider_data[:attributes][:cost]).to eq("$200")
  
      expect(provider_data[:attributes]).to have_key(:min_age)
      expect(provider_data[:attributes][:min_age]).to eq(6.0)
  
      expect(provider_data[:attributes]).to have_key(:max_age)
      expect(provider_data[:attributes][:max_age]).to eq(20.0)
    end
  end  
end