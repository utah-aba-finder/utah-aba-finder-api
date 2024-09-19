class Provider < ApplicationRecord

  has_many :counties
  has_many :locations
  has_many :provider_insurances
  has_many :insurances, through: :provider_insurances

  def update_locations(location_params)
    location_params.each do |location_info|
      # binding.pry
      location = Location.find_by(id: location_info[:id])
      # need to create rescue for not found
      location.update!(
        name: location_info[:name] ,
        address_1: location_info[:address_1] ,
        address_2: location_info[:address_2] ,
        city: location_info[:city] ,
        state: location_info[:state] ,
        zip: location_info[:zip] ,
        phone: location_info[:phone] ,
        email: location_info[:email] 
      )
    end
  end

  def update_provider_insurance(insurance_params)
    # binding.pry
    insurance_params.each do |insurance_info|
      provider_insurance = ProviderInsurance.find_by(insurance_id: insurance_info[:id])
      provider_insurance.update!(accepted: true)
    end
  end
end
