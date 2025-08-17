class Provider < ApplicationRecord
  has_one_attached :logo unless Rails.env.test?
  
  has_many :old_counties
  has_many :counties_providers
  has_many :counties, through: :counties_providers
  has_many :locations
  has_many :provider_insurances
  has_many :insurances, through: :provider_insurances
  has_many :provider_practice_types, dependent: :destroy
  has_many :practice_types, through: :provider_practice_types
  has_many :provider_attributes, dependent: :destroy
  belongs_to :provider_category, optional: true, foreign_key: 'category', primary_key: 'slug'
  
  # New relationship for user management
  belongs_to :user, optional: true

  enum status: { pending: 1, approved: 2, denied: 3 }

  # Validations
  validates :in_home_only, inclusion: { in: [true, false] }
  validates :service_delivery, presence: true
  validates :category, presence: true
  # Only validate logo if it's an Active Storage attachment
  validates :logo, content_type: ['image/png', 'image/jpeg', 'image/gif'], size: { less_than: 5.megabytes }, if: -> { logo.present? && logo.respond_to?(:attached?) && logo.attached? && defined?(ActiveStorageValidations) && Rails.env != 'test' }

  # Custom validation for in-home only providers
  validate :locations_required_unless_in_home_only
  validate :validate_service_delivery_structure

  def remove_logo
    return if Rails.env.test?
    logo.purge if logo.attached?
  end

  def logo_url
    return nil if Rails.env.test?
    
    Rails.logger.debug "Generating logo URL for provider #{id}"
    
    # First check if there's an Active Storage attachment (new format)
    if logo.attached?
      begin
        # Get the configured host for Active Storage
        host = Rails.application.config.active_storage.default_url_options&.dig(:host)
        
        if host.present?
          # Try to generate the URL with explicit host configuration
          Rails.logger.debug "Generating URL with host: #{host}"
          Rails.application.routes.url_helpers.rails_blob_url(logo, host: host)
        else
          # Fallback: try without explicit host
          Rails.logger.debug "Generating URL without explicit host"
          Rails.application.routes.url_helpers.rails_blob_url(logo)
        end
      rescue ArgumentError => e
        # If host is not configured, try with a fallback
        Rails.logger.warn "Could not generate logo URL for provider #{id}: #{e.message}"
        begin
          # Try with localhost as fallback
          Rails.application.routes.url_helpers.rails_blob_url(logo, host: 'localhost:3000')
        rescue => e2
          Rails.logger.error "Fallback logo URL generation failed for provider #{id}: #{e2.message}"
          nil
        end
      rescue => e
        # Catch any other errors that might occur
        Rails.logger.error "Unexpected error generating logo URL for provider #{id}: #{e.message}"
        nil
      end
    # Then check if there's a logo string in the database (legacy format)
    elsif self[:logo].present?
      return self[:logo]
    else
      nil
    end
  end

  def create_practice_types(practice_type_names)
    practice_type_names.each do |param|
      name = param[:name]
      next if name.blank?

      practice_type = PracticeType.find_or_create_by(name: name)
      self.practice_types << practice_type unless self.practice_types.include?(practice_type)
    end
  end

  def category_fields
    provider_category&.category_fields&.active&.ordered || []
  end

  def get_attribute_value(field_name)
    provider_attributes.joins(:category_field)
                      .find_by(category_fields: { name: field_name })&.value
  end

  def set_attribute_value(field_name, value)
    field = category_fields.find_by(name: field_name)
    return false unless field

    attribute = provider_attributes.find_or_initialize_by(category_field: field)
    attribute.value = value
    attribute.save
  end

  def has_attribute?(field_name)
    provider_attributes.joins(:category_field)
                      .where(category_fields: { name: field_name })
                      .exists?
  end

  def required_attributes_complete?
    required_fields = category_fields.where(required: true)
    required_fields.all? { |field| has_attribute?(field.name) }
  end

  def category_display_name
    provider_category&.name || 'Unknown Category'
  end

  #should refactor into smaller methods
  def update_locations(location_params)
    return if location_params.blank?

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
        email: location_info[:email] ,
        in_home_waitlist: location_info[:in_home_waitlist],
        in_clinic_waitlist: location_info[:in_clinic_waitlist]
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
    return if insurance_params.blank?

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
    return if county_ids.blank?

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

  def create_practice_types(practice_type_names)
    return if practice_type_names.blank?

    practice_type_names.each do |params|
      practice_type = PracticeType.find_by(name: params[:name])
      if practice_type && !self.practice_types.include?(practice_type)
        self.practice_types << practice_type
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

  def locations_required_unless_in_home_only
    return if new_record?
    return if in_home_only?
    if locations.empty?
      errors.add(:locations, 'are required unless provider offers in-home services only')
    end
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
end
