class Provider < ApplicationRecord
  # Logo attachment for Active Storage
  has_one_attached :logo unless Rails.env.test?
  
  has_many :old_counties
  has_many :counties_providers, dependent: :destroy
  has_many :counties, through: :counties_providers
  has_many :locations
  belongs_to :primary_location, class_name: 'Location', optional: true
  has_many :provider_insurances
  has_many :insurances, through: :provider_insurances
  has_many :provider_practice_types, dependent: :destroy
  has_many :practice_types, through: :provider_practice_types
  has_many :provider_attributes, dependent: :destroy
  belongs_to :provider_category, optional: true, foreign_key: 'category', primary_key: 'slug'
  
  # New multi-provider type relationships
  has_many :provider_attributes, dependent: :destroy
  belongs_to :provider_category, optional: true, foreign_key: 'category', primary_key: 'slug'
  
  # New relationship for user management
  belongs_to :user, optional: true
  has_many :provider_assignments, dependent: :destroy
  has_many :assigned_users, through: :provider_assignments, source: :user
  
  # Sponsorship relationships
  has_many :sponsorships, dependent: :destroy
  has_one :active_sponsorship, -> { active_sponsorships }, class_name: 'Sponsorship'
  
  # Provider views tracking
  has_many :provider_views, dependent: :destroy

  # Service Type Relationships
  has_many :provider_service_types, dependent: :destroy
  has_many :service_categories, through: :provider_service_types, source: :provider_category
  
  # Backward compatibility - keep existing category field
  # but now it represents the primary service type
  def primary_service_category
    provider_service_types.primary.first&.provider_category || provider_category
  end
  
  def primary_service_category=(category)
    if category.is_a?(ProviderCategory)
      # Find or create the primary service type
      service_type = provider_service_types.find_or_initialize_by(provider_category: category)
      service_type.is_primary = true
      service_type.save!
      
      # Update the legacy category field for backward compatibility
      update_column(:category, category.slug)
    elsif category.is_a?(String)
      # Handle string input (slug)
      cat = ProviderCategory.find_by(slug: category)
      self.primary_service_category = cat if cat
    end
  end
  
  def add_service_type(category, is_primary: false)
    return false if has_service_type?(category)
    
    # If this is being set as primary, unset any existing primary
    if is_primary
      provider_service_types.primary.update_all(is_primary: false)
    end
    
    provider_service_types.create!(
      provider_category: category,
      is_primary: is_primary
    )
    
    # Update legacy category field if this is primary
    update_column(:category, category.slug) if is_primary
    
    true
  end
  
  def remove_service_type(category)
    service_type = provider_service_types.find_by(provider_category: category)
    return false unless service_type
    
    # If removing primary service type, set another as primary if available
    if service_type.is_primary? && provider_service_types.count > 1
      new_primary = provider_service_types.where.not(id: service_type.id).first
      new_primary.update!(is_primary: true)
      update_column(:category, new_primary.provider_category.slug)
    end
    
    service_type.destroy
    true
  end
  
  def has_service_type?(category)
    provider_service_types.exists?(provider_category: category)
  end
  
  def service_types_count
    provider_service_types.count
  end
  
  def multiple_service_types?
    provider_service_types.count > 1
  end

  enum status: { pending: 1, approved: 2, denied: 3 }
  
  # Sponsorship tier enum: free: 0, featured: 1, sponsor: 2, partner: 3
  enum sponsorship_tier: { free: 0, featured: 1, sponsor: 2, partner: 3 }, _prefix: :sponsorship

  # Normalize status before validation
  before_validation :normalize_status

  # Validations
  validates :in_home_only, inclusion: { in: [true, false] }
  validates :service_delivery, presence: true
  validates :category, presence: true, on: :create
  # Only validate logo if it's an Active Storage attachment and not in test environment
  validates :logo, content_type: ['image/png', 'image/jpeg', 'image/gif'], size: { less_than: 5.megabytes }, if: -> { respond_to?(:logo) && logo.respond_to?(:attached?) && logo.attached? && Rails.env != 'test' }

  # Custom validation for in-home only providers
  validate :locations_required_unless_in_home_only
  validate :validate_service_delivery_structure
  validate :primary_location_belongs_to_provider

  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :active_categories, -> { joins(:provider_category).where(provider_categories: { is_active: true }) }

  def remove_logo
    return if Rails.env.test?
    logo.purge if logo.attached?
  end



  # New methods for multi-provider type system
  def category_fields
    return [] unless provider_category
    provider_category.category_fields.active.ordered
  end

  def get_attribute_value(field_name)
    field = category_fields.find_by(name: field_name)
    return nil unless field
    
    attr = provider_attributes.find_by(category_field: field)
    attr&.value
  end

  def set_attribute_value(field_name, value)
    field = category_fields.find_by(name: field_name)
    return false unless field
    
    attr = provider_attributes.find_or_initialize_by(category_field: field)
    attr.value = value
    attr.save
  end

  def has_attribute?(field_name)
    field = category_fields.find_by(name: field_name)
    return false unless field
    
    provider_attributes.exists?(category_field: field)
  end

  def required_attributes_complete?
    required_fields = category_fields.required
    return true if required_fields.empty?
    
    required_fields.all? do |field|
      attr = provider_attributes.find_by(category_field: field)
      attr&.value.present?
    end
  end

  def category_display_name
    provider_category&.name || category.titleize
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
  def update_locations(location_params, primary_location_id: nil)
    return if location_params.blank?

    # Extract IDs handling both symbol and string keys
    location_params_ids = location_params.map { |location| location[:id] || location["id"] }.compact.map(&:to_i)

    Rails.logger.info "🔍 Provider#update_locations - Received #{location_params.count} locations with IDs: #{location_params_ids.inspect}"
    Rails.logger.info "🔍 Provider#update_locations - Primary location ID: #{primary_location_id.inspect}"
    Rails.logger.info "🔍 Provider#update_locations - Current locations count: #{self.locations.count}"

    # Track which location should be primary (from parameter or from location data)
    # Convert to integer if present (handles string "2464" -> 2464)
    new_primary_location_id = if primary_location_id.present?
                                primary_location_id.to_i
                              else
                                nil
                              end

    Rails.logger.info "🔍 Provider#update_locations - new_primary_location_id after conversion: #{new_primary_location_id.inspect}"

    # If primary_location_id not provided, check if any location has primary: true
    if new_primary_location_id.nil? || new_primary_location_id == 0
      primary_location_info = location_params.find { |loc| loc[:primary] == true || loc["primary"] == true }
      if primary_location_info
        # If it's an existing location (has ID), use that ID
        # If it's a new location (no ID), we'll track it and set it after creation
        location_id = primary_location_info[:id] || primary_location_info["id"]
        new_primary_location_id = location_id if location_id.present?
        Rails.logger.info "🔍 Provider#update_locations - Found primary location in params: #{new_primary_location_id || 'new location (will set after creation)'}"
      end
    end

    # Remove locations that are not in the params (handles both symbol and string keys)
    self.locations.each do |location|
      unless location_params_ids.include?(location.id)
        Rails.logger.info "🔍 Provider#update_locations - Removing location ID #{location.id} (#{location.name})"
        # If this was the primary location, clear it
        if self.primary_location_id.to_i == location.id
          update_column(:primary_location_id, nil)
          Rails.logger.info "🔍 Provider#update_locations - Cleared primary_location_id (was location #{location.id})"
        end
        location.destroy
      end
    end

    # Update existing locations or create new ones
    location_params.each do |location_info|
      # Handle both symbol and string keys for ID
      location_id = location_info[:id] || location_info["id"]
      
      # Handle both symbol and string keys for all fields
      location = if location_id.present?
                  Rails.logger.info "🔍 Provider#update_locations - Updating existing location ID #{location_id}"
                  self.locations.find_by(id: location_id)
                else
                  Rails.logger.info "🔍 Provider#update_locations - Creating new location"
                  self.locations.new
                end

      # Extract values handling both symbol and string keys
      phone_value = location_info[:phone] || location_info["phone"]
      Rails.logger.info "🔍 Provider#update_locations - Location #{location_id || 'new'}: phone value received: #{phone_value.inspect}"
      
      location.update!(
        name: location_info[:name] || location_info["name"],
        address_1: location_info[:address_1] || location_info["address_1"],
        address_2: location_info[:address_2] || location_info["address_2"],
        city: location_info[:city] || location_info["city"],
        state: location_info[:state] || location_info["state"],
        zip: location_info[:zip] || location_info["zip"],
        phone: phone_value,
        email: location_info[:email] || location_info["email"],
        in_home_waitlist: location_info[:in_home_waitlist] || location_info["in_home_waitlist"],
        in_clinic_waitlist: location_info[:in_clinic_waitlist] || location_info["in_clinic_waitlist"]
      )
      
      Rails.logger.info "✅ Provider#update_locations - Location #{location.id}: phone saved as: #{location.phone.inspect}"

      # location services update (handle both symbol and string keys)
      # Accept either 'services' or 'practice_types' field
      services = location_info[:services] || location_info["services"]
      practice_types = location_info[:practice_types] || location_info["practice_types"]
      
      Rails.logger.info "🔍 Provider#update_locations - Location #{location.id}: services=#{services.inspect}, practice_types=#{practice_types.inspect}"
      
      # Use practice_types if provided (string array), otherwise use services
      services_to_update = practice_types.present? ? practice_types : services
      Rails.logger.info "🔍 Provider#update_locations - Location #{location.id}: services_to_update=#{services_to_update.inspect}"
      update_location_services(location, services_to_update)
      
      Rails.logger.info "✅ Provider#update_locations - Saved location ID #{location.id} (#{location.name})"
      
      # If this location should be primary and it's a new location (no ID in params), set it as primary
      if new_primary_location_id.nil? && (location_info[:primary] == true || location_info["primary"] == true)
        new_primary_location_id = location.id
        Rails.logger.info "🔍 Provider#update_locations - Setting new location #{location.id} as primary"
      end
    end

    # Set primary location after all locations are saved
    if new_primary_location_id.present?
      if set_primary_location(new_primary_location_id)
        Rails.logger.info "✅ Provider#update_locations - Set primary location to ID #{new_primary_location_id}"
      else
        Rails.logger.warn "⚠️ Provider#update_locations - Failed to set primary location ID #{new_primary_location_id} (location not found)"
      end
    elsif primary_location_id.present? && !location_params_ids.include?(primary_location_id.to_i)
      # Primary location was removed, clear it
      update_column(:primary_location_id, nil)
      Rails.logger.info "🔍 Provider#update_locations - Cleared primary location (was removed)"
    end

    Rails.logger.info "✅ Provider#update_locations - Final locations count: #{self.reload.locations.count}"
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

    # Handle both string array and object array formats
    insurance_ids = if insurance_params.first.is_a?(String)
      # Frontend sends: ["Contact us", "Aetna", ...]
      insurance_params.map { |name| Insurance.find_by(name: name)&.id }.compact
    else
      # Frontend sends: [{"id"=>1, "name"=>"Contact us"}, ...]
      insurance_params.map { |param| param[:id] || param["id"] }.compact
    end

    self.provider_insurances.each do |provider_insurance|
      if insurance_ids.include?(provider_insurance.insurance_id)
        provider_insurance.update!(accepted: true)
      else
        provider_insurance.update!(accepted: false)
      end
    end
  end

  # def update_counties(counties_params)
  #   return if counties_params.blank?

  #   counties_params_ids = counties_params.map { |county| county[:id] }.compact

  #   self.counties.each do |county|
  #     unless counties_params_ids.include?(county.id)
  #       self.counties.delete(county)
  #     end
  #   end

  #   counties_params.each do |county_info|
  #     county = County.find(county_info[:id])
  #     self.counties << county unless self.counties.include?(county)
  #   end
  # end

  def update_counties_from_array(county_ids)
    return if county_ids.blank?

    # Filter out invalid county IDs (0, nil, negative, or non-existent)
    valid_county_ids = county_ids.compact.reject { |id| id.to_i <= 0 }
    
    # Find only valid counties that exist in the database
    valid_counties = County.where(id: valid_county_ids).to_a
    
    # Clear existing counties
    self.counties.clear

    # Add new counties (only valid ones)
    valid_counties.each do |county|
      self.counties << county
    end
    
    Rails.logger.info "✅ Updated counties for provider #{id}: #{valid_counties.map(&:name).join(', ')}"
    Rails.logger.warn "⚠️ Filtered out invalid county IDs: #{(county_ids - valid_county_ids).inspect}" if county_ids.size != valid_county_ids.size
  end

  # Set primary location (safely validates it belongs to provider)
  def set_primary_location(location_id)
    # Convert to integer to ensure proper matching
    location_id = location_id.to_i if location_id.present?
    Rails.logger.info "🔍 set_primary_location - Attempting to set primary_location_id to: #{location_id.inspect} (class: #{location_id.class})"
    Rails.logger.info "🔍 set_primary_location - Provider has #{locations.count} locations with IDs: #{locations.pluck(:id).inspect}"
    
    location = locations.find_by(id: location_id)
    unless location
      Rails.logger.warn "⚠️ set_primary_location - Location ID #{location_id} not found for provider #{id}"
      return false
    end

    result = update_column(:primary_location_id, location_id)
    Rails.logger.info "✅ set_primary_location - Successfully set primary_location_id to #{location_id} (result: #{result.inspect})"
    Rails.logger.info "🔍 set_primary_location - Provider.primary_location_id after update: #{reload.primary_location_id.inspect}"
    true
  end
  public :set_primary_location

  # Get primary location (returns first location if none set, for backward compatibility)
  def primary_location_or_first
    primary_location || locations.order(:id).first
  end

  def create_practice_types(practice_type_params)
    return if practice_type_params.blank?

    practice_type_params.each do |type_info|
      # Handle both name-based and id-based input for backward compatibility
      if type_info[:name].present?
        practice_type = PracticeType.find_by(name: type_info[:name])
        if practice_type
          ProviderPracticeType.create!(
            provider: self,
            practice_type: practice_type
          )
        else
          Rails.logger.warn "Practice type not found by name: #{type_info[:name]}"
        end
      elsif type_info[:id].present?
        # Fallback to ID lookup for backward compatibility
        practice_type = PracticeType.find_by(id: type_info[:id])
        if practice_type
          ProviderPracticeType.create!(
            provider: self,
            practice_type: practice_type
          )
        else
          Rails.logger.warn "Practice type not found by ID: #{type_info[:id]}"
        end
      end
    end
  end

  def update_practice_types(practice_type_params)
    return if practice_type_params.blank?

    # Clear existing practice types
    self.practice_types.clear

    # Add new practice types by name lookup (more robust than ID lookup)
    practice_type_params.each do |type_info|
      # Handle both name-based and id-based input for backward compatibility
      if type_info[:name].present?
        practice_type = PracticeType.find_by(name: type_info[:name])
        if practice_type
          self.practice_types << practice_type
        else
          Rails.logger.warn "Practice type not found by name: #{type_info[:name]}"
        end
      elsif type_info[:id].present?
        # Fallback to ID lookup for backward compatibility
        practice_type = PracticeType.find_by(id: type_info[:id])
        if practice_type
          self.practice_types << practice_type
        else
          Rails.logger.warn "Practice type not found by ID: #{type_info[:id]}"
        end
      end
    end
  end

  def update_location_services(location, services_params)
    # Handle both formats:
    # 1. services: [{id, name}] (preferred)
    # 2. practice_types: ["ABA Therapy", "Speech Therapy"] (alternative)
    
    Rails.logger.info "🔍 update_location_services - Location ID: #{location.id}, services_params: #{services_params.inspect}"
    Rails.logger.info "🔍 update_location_services - services_params class: #{services_params.class}, nil?: #{services_params.nil?}, blank?: #{services_params.blank?}, empty?: #{services_params.is_a?(Array) && services_params.empty?}"
    
    # If services_params is nil/blank/empty array, don't update (preserve existing)
    # Empty array is treated as "preserve existing" to prevent accidental deletion
    if services_params.nil? || services_params.blank? || (services_params.is_a?(Array) && services_params.empty?)
      Rails.logger.info "🔍 update_location_services - Preserving existing services (services_params is nil/blank/empty)"
      return
    end
    
    # Determine which format we received
    if services_params.is_a?(Array) && services_params.any? && services_params.first.is_a?(String)
      # Format: practice_types: ["ABA Therapy", "Speech Therapy"]
      Rails.logger.info "🔍 update_location_services - Using string array format (practice_types)"
      practice_type_names = services_params.map(&:to_s).compact.reject(&:blank?)
      
      if practice_type_names.empty?
        Rails.logger.info "🔍 update_location_services - Preserving existing (all names blank)"
        return  # Preserve if all names are blank
      end
      
      Rails.logger.info "🔍 update_location_services - Clearing existing and adding: #{practice_type_names.inspect}"
      # Clear existing and add new ones by name
      location.practice_types.clear
      practice_type_names.each do |name|
        practice_type = PracticeType.find_by(name: name)
        if practice_type
          location.practice_types << practice_type unless location.practice_types.include?(practice_type)
          Rails.logger.info "✅ update_location_services - Added practice_type: #{name} (ID: #{practice_type.id})"
        else
          Rails.logger.warn "⚠️ Practice type not found by name: #{name}"
        end
      end
      Rails.logger.info "✅ update_location_services - Final practice_types count: #{location.practice_types.count}"
    else
      # Format: services: [{id, name}] or [{id}]
      Rails.logger.info "🔍 update_location_services - Using object array format (services)"
      services_params_ids = services_params.map { |service| service[:id] || service["id"] }.compact.reject { |id| id.to_i <= 0 }
      
      Rails.logger.info "🔍 update_location_services - Extracted IDs: #{services_params_ids.inspect}"
      
      # If no valid IDs found, preserve existing (don't clear accidentally)
      if services_params_ids.empty?
        Rails.logger.info "🔍 update_location_services - Preserving existing (no valid IDs found)"
        return
      end

      # Remove practice types not in the list
      location.practice_types.each do |practice_type|
        unless services_params_ids.include?(practice_type.id)
          Rails.logger.info "🔍 update_location_services - Removing practice_type: #{practice_type.name} (ID: #{practice_type.id})"
          location.practice_types.delete(practice_type)
        end
      end

      # Add new practice types
      services_params.each do |service_info|
        service_id = service_info[:id] || service_info["id"]
        next unless service_id.present? && service_id.to_i > 0
        
        practice_type = PracticeType.find_by(id: service_id)
        if practice_type
          unless location.practice_types.include?(practice_type)
            location.practice_types << practice_type
            Rails.logger.info "✅ update_location_services - Added practice_type: #{practice_type.name} (ID: #{service_id})"
          end
        else
          Rails.logger.warn "⚠️ Practice type not found by ID: #{service_id}"
        end
      end
      Rails.logger.info "✅ update_location_services - Final practice_types count: #{location.practice_types.count}"
    end
  end

  private

  def normalize_status
    return unless status.present?
    
    # Convert capitalized status to lowercase to match enum values
    case status.to_s.downcase
    when 'approved'
      self.status = 'approved'
    when 'pending'
      self.status = 'pending'
    when 'denied'
      self.status = 'denied'
    end
  end

  def locations_required_unless_in_home_only
    # Skip location validation if:
    # 1. Provider is in-home only (no clinic locations needed)
    # 2. Provider only offers telehealth services (no physical locations needed)
    if !in_home_only && !telehealth_only? && locations.empty?
      errors.add(:locations, "are required for clinic-based providers")
    end
  end

  def telehealth_only?
    return false unless service_delivery.present?
    
    service_delivery['telehealth'] == true && 
    service_delivery['in_home'] == false && 
    service_delivery['in_clinic'] == false
  end

  public :telehealth_only?

  def validate_service_delivery_structure
    return unless service_delivery.present?

    unless service_delivery.is_a?(Hash) && service_delivery.key?('in_home') && service_delivery.key?('in_clinic')
      errors.add(:service_delivery, "must have 'in_home' and 'in_clinic' keys")
    end
  end

  private

  def normalize_waitlist_value(value)
    return nil if value.blank?
    
    value = value.to_s.strip
    
    # If value is already a valid option, return it
    return value if Location::WAITLIST_OPTIONS.include?(value)
    
    # Map common invalid values to valid ones
    case value.downcase
    when "this service isn't provided at this location",
         "this service is not provided at this location",
         "service not provided",
         "not provided"
      "No in-home services available at this location"
    when "contact for availability",
         "contact us",
         "call for availability"
      "Contact for availability"
    when "no waitlist",
         "no wait"
      "No waitlist"
    when "not accepting new clients",
         "not accepting clients"
      "Not accepting new clients"
    else
      # Default to "Contact for availability" if unrecognized
      Rails.logger.warn "⚠️ Invalid waitlist value '#{value}', defaulting to 'Contact for availability'"
      "Contact for availability"
    end
  end

  def primary_location_belongs_to_provider
    return unless primary_location_id.present?

    unless locations.exists?(id: primary_location_id)
      errors.add(:primary_location_id, "must be one of the provider's locations")
    end
  end
end
