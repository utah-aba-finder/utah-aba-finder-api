class Provider < ApplicationRecord

  has_many :counties
  has_many :locations
  has_many :provider_insurances
  has_many :insurances, through: :provider_insurances

  enum status: { pending: 1, approved: 2, denied: 3 }

  # Validations for new fields
  validates :in_home_only, inclusion: { in: [true, false] }
  validates :service_delivery, presence: true
  validates :service_area, presence: true

  # Custom validations
  validate :validate_service_delivery_structure
  validate :validate_service_area_structure
  validate :locations_required_unless_in_home_only

  def locations_required_unless_in_home_only
    # Only validate if the provider is being updated and has been saved before
    return if new_record?
    
    if !in_home_only && locations.empty?
      errors.add(:locations, 'are required unless provider offers in-home services only')
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

  # New methods for service area management
  def update_service_area(states: nil, counties: nil)
    current_service_area = self.service_area || { states_served: [], counties_served: [] }
    
    if states
      current_service_area['states_served'] = states
    end
    
    if counties
      current_service_area['counties_served'] = counties
    end
    
    update!(service_area: current_service_area)
  end

  def update_service_delivery(in_home: nil, in_clinic: nil, telehealth: nil)
    current_service_delivery = self.service_delivery || { in_home: false, in_clinic: false, telehealth: false }
    
    current_service_delivery['in_home'] = in_home if in_home != nil
    current_service_delivery['in_clinic'] = in_clinic if in_clinic != nil
    current_service_delivery['telehealth'] = telehealth if telehealth != nil
    
    update!(service_delivery: current_service_delivery)
  end

  private

  def validate_service_delivery_structure
    return unless service_delivery.present?
    
    unless service_delivery.is_a?(Hash) && 
           service_delivery.key?('in_home') && 
           service_delivery.key?('in_clinic') && 
           service_delivery.key?('telehealth')
      errors.add(:service_delivery, 'must have in_home, in_clinic, and telehealth keys')
    end
  end

  def validate_service_area_structure
    return unless service_area.present?
    
    unless service_area.is_a?(Hash) && 
           service_area.key?('states_served') && 
           service_area.key?('counties_served')
      errors.add(:service_area, 'must have states_served and counties_served keys')
    end
  end
end
