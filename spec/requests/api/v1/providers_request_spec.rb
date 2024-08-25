require "rails_helper"

describe "Providers Requests" do
  context "get /api/v1/providers" do
    it "returns all providers with provider attributes" do

      get "/api/v1/providers"

      expect(response).to be_successful
      expect(response.status).to eq(200)

      providers_response = JSON.parse(response.body, symbolize_names: true)

      expect(providers_response).to be_an(Hash)

      expect(providers_response).to have_key(:data)
      expect(providers_response[:data]).to be_a(Array)
      expect(providers_response[:data].size).to eq(2)

      expect(providers_response[:data].first).to have_key(:id)
      expect(providers_response[:data].first[:id]).to eq(active_subscription.id)

      expect(providers_response[:data].first[:attributes]).to have_key(:name)
      expect(providers_response[:data].first[:attributes][:name]).to a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:website)
      expect(providers_response[:data].first[:attributes][:website]).to a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:phone)
      expect(providers_response[:data].first[:attributes][:phone]).to a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:email)
      expect(providers_response[:data].first[:attributes][:email]).to a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:cost)
      expect(providers_response[:data].first[:attributes][:cost]).to a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:ages_served)
      expect(providers_response[:data].first[:attributes][:ages_served]).to a(String)

      expect(providers_response[:data].first[:attributes]).to have_key(:waitlist)
      expect(providers_response[:data].first[:attributes][:waitlist]).to a(Integer)

      expect(providers_response[:data].first[:attributes]).to have_key(:telehealth_services)
      expect(providers_response[:data].first[:attributes][:telehealth_services]).to a(Integer)

      expect(providers_response[:data].first[:attributes]).to have_key(:spanish_speakers)
      expect(providers_response[:data].first[:attributes][:spanish_speakers]).to a(Integer)

      expect(providers_response[:data].first[:attributes]).to have_key(:insurance)
      expect(providers_response[:data].first[:attributes][:insurance]).to a(Array)
      
      providers_response[:data].first[:attributes][:insurance].each do |insurance|
        expect(insurance).to be_a(Hash)
        expect(insurance).to have_key(:name)
        expect(insurance[:name]).to be_a(String)
      end

      expect(providers_response[:data].first[:attributes]).to have_key(:locations)
      expect(providers_response[:data].first[:attributes][:locations]).to a(Array)

      providers_response[:data].first[:attributes][:locations].each do |location|
        expect(location).to be_a(Hash)
        expect(location).to have_key(:name)
        expect(location[:name]).to be_a(String)
      end

      expect(providers_response[:data].first[:attributes]).to have_key(:areas_served)
      expect(providers_response[:data].first[:attributes][:areas_served]).to a(Array)

      providers_response[:data].first[:attributes][:areas_served].each do |area_served|
        expect(area_served).to be_a(Hash)
        expect(area_served).to have_key(:name)
        expect(area_served[:name]).to be_a(String)
      end
    end
  end
end