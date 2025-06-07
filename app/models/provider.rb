class Provider < ApplicationRecord

  has_many :old_counties
  has_many :counties_providers
  has_many :counties, through: :counties_providers
  has_many :locations
  has_many :provider_insurances
  has_many :insurances, through: :provider_insurances
  has_many :provider_practice_types, dependent: :destroy
  has_many :practice_types, through: :provider_practice_types

  enum status: { pending: 1, approved: 2, denied: 3 }

  def create_practice_types(practice_type_names)
    practice_type_names.each do |param|
      name = param[:name]
      next if name.blank?

      practice_type = PracticeType.find_or_create_by(name: name)
      self.practice_types << practice_type unless self.practice_types.include?(practice_type)
    end
  end

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

      # location services update
      update_location_services(location, location_info[:services])
    end

    self.reload
  end

  def initialize_provider_insurances
    Insurance.all.each do |insurance|
      ProviderInsurance.create!(
        provider: self,
        insurance: insurance,
        accepted: false
      )
    end
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

  # def update_counties(counties_params)
  #   counties_params.each do |county_info|
  #     # self.old_counties.update!(counties_served: county_info[:county])
  #   end
  # end

  def update_counties_from_array(county_ids)
    counties_to_remove = self.counties.where.not(id: county_ids)
    self.counties.delete(counties_to_remove)

    county_ids.each do |county_id|
      county = County.find_by(id: county_id)
      self.counties << county if county && !self.counties.include?(county)
    end
  end

  def update_practice_types(practice_type_names)
    return if practice_type_names.blank?

    new_practice_types = practice_type_names.map do |params|
      PracticeType.find_by(name: params[:name])
    end.compact

    new_practice_types.each do |practice_type|
      unless self.practice_types.include?(practice_type)
        self.practice_types << practice_type
      end
    end

    self.practice_types.each do |practice_type|
      unless new_practice_types.include?(practice_type)
        self.practice_types.delete(practice_type)
      end
    end
  end

  private

  def update_location_services(location, services_params)
    return if services_params.blank?

    # Get the practice type IDs from the services params
    service_ids = services_params.map { |service| service[:id] }.compact

    # Remove practice types that are no longer associated with this location
    location.practice_types.each do |practice_type|
      unless service_ids.include?(practice_type.id)
        location.practice_types.delete(practice_type)
      end
    end

    # Add new practice types to the location
    service_ids.each do |service_id|
      practice_type = PracticeType.find_by(id: service_id)
      if practice_type && !location.practice_types.include?(practice_type)
        location.practice_types << practice_type
      end
    end
  end
end
