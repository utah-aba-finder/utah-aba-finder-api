class Provider < ApplicationRecord

  has_many :counties
  has_many :locations
  has_many :provider_insurances
  has_many :insurances, through: :provider_insurances

  enum status: { pending: 1, approved: 2, denied: 3 }
  #should refactor into smaller methods
  def update_locations(location_params)
    location_params_ids = location_params.map { |location| location[:id] }.compact

    self.locations.each do |location|
      unless location_params_ids.include?(location.id)
        location.destroy
      end
    end

    location_params.each do |location_info|
      location = if location_info[:id].present?
                  self.locations.find_by(id: location_info[:id])
                else
                  self.locations.new
                end

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

    self.reload
  end

  def update_provider_insurance(insurance_params)
    array = insurance_params.map do |param|
      param[:id]
    end
    self.provider_insurances.each do |provider_info|
      if array.include?(provider_info[:insurance_id])
        provider_insurance = self.provider_insurances.find_by(insurance_id: provider_info[:insurance_id])
        provider_insurance.update!(accepted: true)
      else
        provider_insurance = self.provider_insurances.find_by(insurance_id: provider_info[:insurance_id])
        provider_insurance.update!(accepted: false)
      end
    end
  end

  def update_counties(counties_params)
    counties_params.each do |county_info|
      self.counties.update!(counties_served: county_info[:county])
    end
  end
end
