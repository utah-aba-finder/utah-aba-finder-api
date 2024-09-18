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
    @insurance3 = Insurance.create!(name: "Insurance C")

    @pi1 = ProviderInsurance.create!(provider: @provider, insurance: @insurance1)
    @pi2 = ProviderInsurance.create!(provider: @provider, insurance: @insurance2)

    @location1 = Location.create!(
      provider: @provider,
      name: "Location 1",
      address_1: "123 Main St",
      address_2: "Suite 100",
      city: "Salt Lake City",
      state: "UT",
      zip: "84101",
      phone: "555-1234",
    )

    County.create!(provider: @provider, counties_served: "Salt Lake County")
    County.create!(provider: @provider, counties_served: "Davis County")
  end

  context "patch /api/v1/providers/:id" do
    it "can update a provider's existing attributes" do
      updated_attributes_json = {
        "data": [
          {
            "id": "#{@provider.id}",
            "type": "provider",
            "attributes": {
              "name": "Provider 1",
              "locations": [
                {
                  "id": "#{@location1.id}",
                  "name": "Cool location name",
                  "address_1": "123 Main St",
                  "address_2": "Suite 100",
                  "city": "Salt Lake City",
                  "state": "UT",
                  "zip": "84101",
                  "phone": "801-435-8088"
                }
              ],
              "website": "https://www.bridgecareaba.com/locations/utah",
              "email": "info@bridgecareaba.com",
              "cost": "N/A",
              "insurance": [
                {
                  "name": "Insurance A",
                  "id": "#{@insurance1.id}"
                },
                {
                  "name": "Insurance C",
                  "id": "#{@insurance3.id}"
                }
              ],
              "counties_served": [
                {
                  "county": "Salt Lake County, Weber County"
                }
              ],
              "min_age": 2.0,
              "max_age": 16.0,
              "waitlist": "No",
              "telehealth_services": "Yes",
              "spanish_speakers": "Yes",
              "at_home_services": "Yes",
              "in_clinic_services": "Yes",
              "logo": "https://awesomelogo.com"
            }
          }
        ]
      }

      patch "/api/v1/providers/#{@provider.id}", params: updated_attributes_json, headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }
      
      #update provider_insurance -> we will be getting a provider_id and insurance_id (main) 
      # use AR to cross reference the existing provider_insurance rows against the received ids and 
      # can update or create or delete based on some ruby logic 

      expect(response).to be_successful
      expect(response.status).to eq(200)
  
      provider_response = JSON.parse(response.body, symbolize_names: true)
      
      expect(provider_response).to be_an(Hash)
      
      provider_data = provider_response[:data].first
  
      expect(provider_data).to have_key(:id)
      expect(provider_data[:id]).to eq(@provider.id)
  
      expect(provider_data[:attributes]).to have_key(:name)
      expect(provider_data[:attributes][:name]).to eq("Provider 1")

      expect(provider_response[:attributes]).to have_key(:website)
      expect(provider_response[:attributes][:website]).to be_a(String)
  
      expect(provider_data[:attributes]).to have_key(:email)
      expect(provider_data[:attributes][:email]).to eq("info@bridgecareaba.com")
  
      expect(provider_data[:attributes]).to have_key(:cost)
      expect(provider_data[:attributes][:cost]).to eq("N/A")
  
      expect(provider_data[:attributes]).to have_key(:min_age)
      expect(provider_data[:attributes][:min_age]).to eq(2.0)
  
      expect(provider_data[:attributes]).to have_key(:max_age)
      expect(provider_data[:attributes][:max_age]).to eq(16.0)
      
      expect(provider_response[:attributes]).to have_key(:waitlist)
      expect(provider_response[:attributes][:waitlist]).to eq("Yes")

      expect(provider_response[:attributes]).to have_key(:telehealth_services)
      expect(provider_response[:attributes][:telehealth_services]).to eq("Yes")

      expect(provider_response[:attributes]).to have_key(:at_home_services)
      expect(provider_response[:attributes][:at_home_services]).to eq("Yes")

      expect(provider_response[:attributes]).to have_key(:in_clinic_services)
      expect(provider_response[:attributes][:in_clinic_services]).to eq("Yes")

      expect(provider_response[:attributes]).to have_key(:spanish_speakers)
      expect(provider_response[:attributes][:spanish_speakers]).to eq("Yes")

      expect(provider_response[:attributes]).to have_key(:logo)
      expect(provider_response[:attributes][:logo]).to eq("https://awesomelogo.com")

      expect(provider_response[:attributes]).to have_key(:insurance)
      expect(provider_response[:attributes][:insurance]).to be_a(Array)
      
      expect(provider_response[:attributes][:insurance].length).to eq(2)
      expect(provider_response[:attributes][:insurance].first.name).to eq("Insurance A")
      expect(provider_response[:attributes][:insurance].first.id).to eq(@insurance1.id)
      expect(provider_response[:attributes][:insurance][1].name).to eq("Insurance C")
      expect(provider_response[:attributes][:insurance][1].id).to eq(@insurance3.id)

      expect(provider_response[:attributes]).to have_key(:locations)
      expect(provider_response[:attributes][:locations]).to be_a(Array)

      expect(provider_response[:attributes][:locations].first.name).to_eq("Cool location name")
      expect(provider_response[:attributes][:locations].first.address_1).to_eq("123 Main St")
      expect(provider_response[:attributes][:locations].first.address_2).to_eq("Suite 100")
      expect(provider_response[:attributes][:locations].first.city).to_eq("Salt Lake City")
      expect(provider_response[:attributes][:locations].first.state).to_eq("UT")
      expect(provider_response[:attributes][:locations].first.zip).to_eq("84101")
      expect(provider_response[:attributes][:locations].first.phone).to_eq("801-435-8088")

      expect(provider_response[:attributes]).to have_key(:counties_served)
      expect(provider_response[:attributes][:counties_served]).to be_a(Array)

      expect(provider_response[:attributes][:counties_served][0][:counties]).to_eq("Salt Lake County, Weber County")
    end
  end  
end