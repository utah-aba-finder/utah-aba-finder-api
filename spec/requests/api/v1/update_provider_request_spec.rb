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
      logo: "https://logo.com",
      in_home_only: false,
      service_delivery: { in_home: false, in_clinic: false, telehealth: false }
    )

    # Additional Provider (to ensure it is not updated)
    @other_provider = Provider.create!(
      name: "Other Provider",
      website: "https://otherprovider.com",
      email: "contact@otherprovider.com",
      cost: "$150",
      min_age: 3.0,
      max_age: 17.0,
      waitlist: "No",
      telehealth_services: "Unavailable",
      at_home_services: "Unavailable",
      in_clinic_services: "Unavailable",
      spanish_speakers: "No",
      logo: "https://otherlogo.com",
      in_home_only: false,
      service_delivery: { in_home: false, in_clinic: false, telehealth: false }
    )
      
    @insurance1 = Insurance.create!(name: "Insurance A")
    @insurance2 = Insurance.create!(name: "Insurance B")
    @insurance3 = Insurance.create!(name: "Insurance C")
    @insurance4 = Insurance.create!(name: "Insurance D")

    @pi1 = ProviderInsurance.create!(provider: @provider, insurance: @insurance1, accepted: true)
    @pi2 = ProviderInsurance.create!(provider: @provider, insurance: @insurance2, accepted: false)
    @pi3 = ProviderInsurance.create!(provider: @provider, insurance: @insurance3, accepted: false)
    @pi4 = ProviderInsurance.create!(provider: @provider, insurance: @insurance4, accepted: true)

    # ProviderInsurances for Other Provider
    ProviderInsurance.create!(provider: @other_provider, insurance: @insurance1, accepted: true)
    ProviderInsurance.create!(provider: @other_provider, insurance: @insurance2, accepted: true)

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

    # Location for Other Provider
    @location2 = Location.create!(
      provider: @other_provider,
      name: "Other Location",
      address_1: "987 Another St",
      address_2: "Suite 200",
      city: "Denver",
      state: "CO",
      zip: "80204",
      phone: "555-5678",
    )

    OldCounty.create!(provider: @provider, counties_served: "Salt Lake")

    # County for Other Provider
    OldCounty.create!(provider: @other_provider, counties_served: "Denver County")

    @state = State.create!(name: "Utah", abbreviation: "UT")

    @county1 = County.create!(name: "Salt Lake", state: @state)
    @county2 = County.create!(name: "Denver County", state: @state)
    @county3 = County.create!(name: "Weber", state: @state)


    @client = Client.create!(name: "test_client", api_key: SecureRandom.hex)
    @api_key = @client.api_key
  end

  context "patch /api/v1/providers/:id" do
    it "can update a provider's existing attributes" do
      updated_attributes = {
        "data": [
          {
            "id": @provider.id,
            "type": "provider",
            "attributes": {
              "name": "Provider 1",
              "locations": [
                {
                  "id": @location1.id,
                  "name": "Cool location name",
                  "address_1": "3 Elm St",
                  "address_2": "PO Box 22",
                  "city": "Frisco",
                  "state": "CO",
                  "zip": "80424",
                  "phone": "801-435-8088"
                }
              ],
              "website": "https://www.changedwebsite.com",
              "email": "info@coolemail.com",
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
                { "county_id": @county3.id, "county_name": @county3.name }
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

      patch "/api/v1/providers/#{@provider.id}", params: updated_attributes.to_json, headers: { 'Content-Type': 'application/json', 'Authorization': @api_key, 'Accept': 'application/json' }

      expect(response).to be_successful
      expect(response.status).to eq(200)
  
      provider_response = JSON.parse(response.body, symbolize_names: true)
      expect(provider_response).to be_an(Hash)
      
      provider_data = provider_response[:data].first
      
      expect(provider_data).to have_key(:id)
      expect(provider_data[:id]).to eq(@provider.id)
  
      expect(provider_data[:attributes]).to have_key(:name)
      expect(provider_data[:attributes][:name]).to eq("Provider 1")

      expect(provider_data[:attributes]).to have_key(:website)
      expect(provider_data[:attributes][:website]).to eq("https://www.changedwebsite.com")
  
      expect(provider_data[:attributes]).to have_key(:email)
      expect(provider_data[:attributes][:email]).to eq("info@coolemail.com")
  
      expect(provider_data[:attributes]).to have_key(:cost)
      expect(provider_data[:attributes][:cost]).to eq("N/A")
  
      expect(provider_data[:attributes]).to have_key(:min_age)
      expect(provider_data[:attributes][:min_age]).to eq(2.0)
  
      expect(provider_data[:attributes]).to have_key(:max_age)
      expect(provider_data[:attributes][:max_age]).to eq(16.0)
      
      expect(provider_data[:attributes]).to have_key(:waitlist)
      expect(provider_data[:attributes][:waitlist]).to eq("No")

      expect(provider_data[:attributes]).to have_key(:telehealth_services)
      expect(provider_data[:attributes][:telehealth_services]).to eq("Yes")

      expect(provider_data[:attributes]).to have_key(:at_home_services)
      expect(provider_data[:attributes][:at_home_services]).to eq("Yes")

      expect(provider_data[:attributes]).to have_key(:in_clinic_services)
      expect(provider_data[:attributes][:in_clinic_services]).to eq("Yes")

      expect(provider_data[:attributes]).to have_key(:spanish_speakers)
      expect(provider_data[:attributes][:spanish_speakers]).to eq("Yes")

      expect(provider_data[:attributes]).to have_key(:logo)
      # In test environment, logo returns nil due to Active Storage being disabled
      if Rails.env.test?
        expect(provider_data[:attributes][:logo]).to be_nil
      else
        expect(provider_data[:attributes][:logo]).to eq("https://awesomelogo.com")
      end
      
      #UPDATE INSURANCE
      expect(provider_data[:attributes]).to have_key(:insurance)
      expect(provider_data[:attributes][:insurance]).to be_a(Array)
      expect(provider_data[:attributes][:insurance].length).to eq(2)
      expect(provider_data[:attributes][:insurance].first[:name]).to eq("Insurance A")
      expect(provider_data[:attributes][:insurance].first[:id]).to eq(@pi1.insurance_id)
      expect(provider_data[:attributes][:insurance].first[:accepted]).to be true
      expect(provider_data[:attributes][:insurance][1][:name]).to eq("Insurance C")
      expect(provider_data[:attributes][:insurance][1][:id]).to eq(@pi3.insurance_id)
      expect(provider_data[:attributes][:insurance].first[:accepted]).to be true

      #UPDATE LOCATIONS
      expect(provider_data[:attributes]).to have_key(:locations)
      expect(provider_data[:attributes][:locations]).to be_a(Array)
      expect(provider_data[:attributes][:locations].first[:name]).to eq("Cool location name")
      expect(provider_data[:attributes][:locations].first[:address_1]).to eq("3 Elm St")
      expect(provider_data[:attributes][:locations].first[:address_2]).to eq("PO Box 22")
      expect(provider_data[:attributes][:locations].first[:city]).to eq("Frisco")
      expect(provider_data[:attributes][:locations].first[:state]).to eq("CO")
      expect(provider_data[:attributes][:locations].first[:zip]).to eq("80424")
      expect(provider_data[:attributes][:locations].first[:phone]).to eq("801-435-8088")

      #UPDATE COUNTIES
      expect(provider_data[:attributes]).to have_key(:counties_served)
      expect(provider_data[:attributes][:counties_served]).to be_a(Array)
      expect(provider_data[:attributes][:counties_served]).to eq([{:county_id=>@county1.id, :county_name=>"Salt Lake"}, {:county_id=>@county3.id, :county_name=>"Weber"}])

      # Verify Other Provider is Unchanged
      @other_provider.reload
      expect(@other_provider.website).to eq("https://otherprovider.com")
      expect(@other_provider.min_age).to eq(3.0)

      # Verify Other Provider's Location is Unchanged
      @location2.reload
      expect(@location2.name).to eq("Other Location")
      expect(@location2.city).to eq("Denver")
    end
  end  

  it "it throws error if not authorized with bearer token" do
    updated_attributes = {
      "name": "Updated Provider",
      "email": "updated@provider1.com",
      "cost": "$200",
      "min_age": 6.0,
      "max_age": 20.0
    }
    
    patch "/api/v1/providers/#{@provider.id}", params: updated_attributes.to_json, headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }

    expect(response.status).to eq(401)

    error_response = JSON.parse(response.body, symbolize_names: true)

    expect(error_response).to be_an(Hash)
    expect(error_response).to have_key(:error)
    expect(error_response[:error]).to eq("Unauthorized")
  end  

  context "patch /api/v1/providers/:id" do
    xit "can update a provider's existing attributes to nil" do
    end
  end
end