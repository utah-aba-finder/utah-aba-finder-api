require "rails_helper"

RSpec.describe "Create Provider Request", type: :request do

  context "post /api/v1/providers" do
    xit "creates a new provider and locations with associations to counties and insurances, then returns the created provider in json format" do
      provider_attributes = {
        "name": "ABA Initiative",
        "locations": [
          {
          name: "ABA Initiative 1",
          address_1: "1234 Aba S",
          address_2: "5678 Ana S",
          city: "Layton",
          state: "Utah",
          zip: "84040",
          phone: "123-123-1234"
          },
          {
          name: "ABA Initiative 2",
          address_1: "1234 Aba A",
          address_2: "5678 Ana A",
          city: "Layton",
          state: "Utah",
          zip: "84040",
          phone: "123-123-4321"
          }
        ],
        "website": "example@example.com",
        "email": "example@email.com",
        "cost": "private pay",
        "insurance": [
          { name: "Insurance A"},
          { name: "Insurance B"}
        ],
        "counties_served": "Davis, Salt Lake, Weber",
        "min_age": 6,
        "max_age": 12,
        "waitlist": "none",
        "telehealth_services": "yes",
        "spanish_speakers": "",
        "at_home_services": "yes",
        "in_clinic_services": "yes",
        "logo": "",
        "npi": "1234"
      }

      expect(Provider.all.count).to eq(0)

      post "/api/v1/providers", params: provider_attributes.to_json, headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }

      expect(response).to be_successful
      expect(Provider.all.count).to eq(1)
      expect(response.status).to eq(200)

      provider_response = JSON.parse(response.body, symbolize_names: true)

      expect(provider_response).to be_an(Hash)

      expect(provider_response).to have_key(:data)
      expect(provider_response[:data]).to be_a(Array)
      expect(provider_response[:data].size).to eq(1)

      expect(provider_response[:data].first).to have_key(:id)
      expect(provider_response[:data].first[:id]).to be_a(Integer)

      expect(provider_response[:data].first[:attributes]).to have_key(:name)
      expect(provider_response[:data].first[:attributes][:name]).to eq("ABA Initiative")

      expect(provider_response[:data].first[:attributes]).to have_key(:website)
      expect(provider_response[:data].first[:attributes][:website]).to eq("example@example.com")

      expect(provider_response[:data].first[:attributes]).to have_key(:email)
      expect(provider_response[:data].first[:attributes][:email]).to eq("example@email.com")

      expect(provider_response[:data].first[:attributes]).to have_key(:cost)
      expect(provider_response[:data].first[:attributes][:cost]).to eq("private pay")

      expect(provider_response[:data].first[:attributes]).to have_key(:min_age)
      expect(provider_response[:data].first[:attributes][:min_age]).to eq(6)

      expect(provider_response[:data].first[:attributes]).to have_key(:max_age)
      expect(provider_response[:data].first[:attributes][:max_age]).to eq(12)

      expect(provider_response[:data].first[:attributes]).to have_key(:waitlist)
      expect(provider_response[:data].first[:attributes][:waitlist]).to eq("none")

      expect(provider_response[:data].first[:attributes]).to have_key(:telehealth_services)
      expect(provider_response[:data].first[:attributes][:telehealth_services]).to eq("yes")

      expect(provider_response[:data].first[:attributes]).to have_key(:at_home_services)
      expect(provider_response[:data].first[:attributes][:at_home_services]).to eq("yes")

      expect(provider_response[:data].first[:attributes]).to have_key(:in_clinic_services)
      expect(provider_response[:data].first[:attributes][:in_clinic_services]).to eq("yes")

      expect(provider_response[:data].first[:attributes]).to have_key(:spanish_speakers)
      expect(provider_response[:data].first[:attributes][:spanish_speakers]).to eq("")

      expect(provider_response[:data].first[:attributes]).to have_key(:logo)
      expect(provider_response[:data].first[:attributes][:logo]).to eq("")

      expect(provider_response[:data].first[:attributes]).to have_key(:insurance)
      expect(provider_response[:data].first[:attributes][:insurance]).to include ([{name: "Insurance A"}, {name: "Insurance B"}])

      expect(provider_response[:data].first[:attributes]).to have_key(:locations)
      expect(provider_response[:data].first[:attributes][:locations]).to be_a(Array)
      expect(provider_response[:data].first[:attributes][:locations].length).to eq(2)

      provider_response[:data].first[:attributes][:locations].each do |location|
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

      expect(provider_response[:data].first[:attributes]).to have_key(:counties_served)
      expect(provider_response[:data].first[:attributes][:counties_served]).to be_a(Array)
      expect(provider_response[:data].first[:attributes][:counties_served].length).to eq(1)

      provider_response[:data].first[:attributes][:counties_served].each do |area_served|
        expect(area_served).to be_a(Hash)
        expect(area_served).to have_key(:county)
        expect(area_served[:county]).to be_a(String)
      end

      expect(Provider.all.count).to eq(2)
      expect(Provider.last.name).to eq("ABA Initiative")
    end
  end 
end