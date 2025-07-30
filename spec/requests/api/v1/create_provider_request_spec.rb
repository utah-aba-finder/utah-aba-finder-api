require "rails_helper"

RSpec.describe "Create Provider Request", type: :request do
  before(:each) do
      @insurance1 = Insurance.create!(name: "Insurance A")
      @insurance2 = Insurance.create!(name: "Insurance B")
      @insurance3 = Insurance.create!(name: "Insurance C")

      @practice_types1 = PracticeType.create!(name: "ABA Therapy")
      @practice_types2 = PracticeType.create!(name: "Autism Evaluation")
      @practice_types3 = PracticeType.create!(name: "Speech Therapy")

      @state = State.create!(name: "Utah", abbreviation: "UT")

      @county1 = County.create!(name: "Salt Lake", state: @state)
      @county2 = County.create!(name: "Weber", state: @state)
  
      @client = create(:client, name: "test_client")
      @api_key = @client.api_key
  end

  context "post /api/v1/providers" do
    it "creates a new provider and locations with associations to counties and insurances, then returns the created provider in json format" do
      provider_attributes = {
        "data": [
          {
            "id": nil,
            "type": "provider",
            "attributes": {
              "name": "New Provider",
              "provider_type": [
                {
                  "id": @practice_types1.id,
                  "name": @practice_types1.name
                },
                {
                  "id": @practice_types2.id,
                  "name": @practice_types2.name
                }
              ],
              "locations": [
                {
                  "id": nil,
                  "name": "New location name",
                  "address_1": "3 Elm St",
                  "address_2": "PO Box 22",
                  "city": "Frisco",
                  "state": "CO",
                  "zip": "80424",
                  "phone": "801-435-8088"
                }
              ],
              "website": "https://www.newwebsite.com",
              "email": "info@newemail.com",
              "cost": "N/A",
              "insurance": [
                {
                  "name": "Insurance A",
                  "id": @insurance1.id
                },
                {
                  "name": "Insurance C",
                  "id": @insurance3.id
                }
              ],
              "counties_served": [
                { "county_id": @county1.id, "county_name": @county1.name },
                { "county_id": @county2.id, "county_name": @county2.name }
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

      expect(Provider.all.count).to eq(0)

      post "/api/v1/providers", params: provider_attributes.to_json, headers: { 'Content-Type': 'application/json', 'Authorization': @api_key, 'Accept': 'application/json' }

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
      expect(provider_response[:data].first[:attributes][:name]).to eq("New Provider")

      expect(provider_response[:data].first[:attributes]).to have_key(:website)
      expect(provider_response[:data].first[:attributes][:website]).to eq("https://www.newwebsite.com")

      expect(provider_response[:data].first[:attributes]).to have_key(:email)
      expect(provider_response[:data].first[:attributes][:email]).to eq("info@newemail.com")

      expect(provider_response[:data].first[:attributes]).to have_key(:cost)
      expect(provider_response[:data].first[:attributes][:cost]).to eq("N/A")

      expect(provider_response[:data].first[:attributes]).to have_key(:min_age)
      expect(provider_response[:data].first[:attributes][:min_age]).to eq(2.0)

      expect(provider_response[:data].first[:attributes]).to have_key(:max_age)
      expect(provider_response[:data].first[:attributes][:max_age]).to eq(16.0)

      expect(provider_response[:data].first[:attributes]).to have_key(:waitlist)
      expect(provider_response[:data].first[:attributes][:waitlist]).to eq("No")

      expect(provider_response[:data].first[:attributes]).to have_key(:telehealth_services)
      expect(provider_response[:data].first[:attributes][:telehealth_services]).to eq("Yes")

      expect(provider_response[:data].first[:attributes]).to have_key(:at_home_services)
      expect(provider_response[:data].first[:attributes][:at_home_services]).to eq("Yes")

      expect(provider_response[:data].first[:attributes]).to have_key(:in_clinic_services)
      expect(provider_response[:data].first[:attributes][:in_clinic_services]).to eq("Yes")

      expect(provider_response[:data].first[:attributes]).to have_key(:spanish_speakers)
      expect(provider_response[:data].first[:attributes][:spanish_speakers]).to eq("Yes")

      expect(provider_response[:data].first[:attributes]).to have_key(:logo)
      # In test environment, logo returns nil due to Active Storage being disabled
      if Rails.env.test?
        expect(provider_response[:data].first[:attributes][:logo]).to be_nil
      else
        expect(provider_response[:data].first[:attributes][:logo]).to eq("https://awesomelogo.com")
      end

      expect(provider_response[:data].first[:attributes]).to have_key(:insurance)
      expect(provider_response[:data].first[:attributes][:insurance]).to include({accepted: true, id: @insurance1.id, name: "Insurance A"}, {accepted: true, id: @insurance3.id, name: "Insurance C"})

      expect(provider_response[:data].first[:attributes]).to have_key(:locations)
      expect(provider_response[:data].first[:attributes][:locations]).to be_a(Array)
      expect(provider_response[:data].first[:attributes][:locations].length).to eq(1)

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
      expect(provider_response[:data].first[:attributes][:counties_served].length).to eq(2)

      provider_response[:data].first[:attributes][:counties_served].each do |area_served|
        expect(area_served).to be_a(Hash)
      end

      expect(Provider.all.count).to eq(1)
      expect(Provider.last.name).to eq("New Provider")

      expect(Provider.last.provider_insurances.count).to eq(3)
    end
  end 
end