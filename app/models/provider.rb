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
  
  # New multi-provider type relationships
  has_many :provider_attributes, dependent: :destroy
  belongs_to :provider_category, optional: true, foreign_key: 'category', primary_key: 'slug'
  
  # New relationship for user management
  belongs_to :user, optional: true
  has_many :provider_assignments, dependent: :destroy
  has_many :assigned_users, through: :provider_assignments, source: :user

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

  # Validations
  validates :in_home_only, inclusion: { in: [true, false] }
  validates :service_delivery, presence: true
  validates :category, presence: true, on: :create
  # Only validate logo if it's an Active Storage attachment
  validates :logo, content_type: ['image/png', 'image/jpeg', 'image/gif'], size: { less_than: 5.megabytes }, if: -> { logo.respond_to?(:attached?) && logo.attached? && Rails.env != 'test' }

  # Custom validation for in-home only providers
  validate :locations_required_unless_in_home_only
  validate :validate_service_delivery_structure

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

    # Handle both string array and object array formats
    insurance_ids = if insurance_params.first.is_a?(String)
      # Frontend sends: ["Contact us", "Aetna", ...]
      insurance_params.map { |name| Insurance.find_by(name: name)&.id }.compact
    else
      # Frontend sends: [{"id"=>1, "name"=>"Contact us"}, ...]
      insurance_params.map { |param| param[:id] }.compact
    end

    self.provider_insurances.each do |provider_info|
      if insurance_ids.include?(provider_info[:insurance_id])
        provider_insurance = self.provider_insurances.find_by(insurance_id: provider_info[:insurance_id])
        provider_insurance.update!(accepted: true)
      else
        provider_insurance = self.provider_insurances.find_by(insurance_id: provider_info[:insurance_id])
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

    # Clear existing counties
    self.counties.clear

    # Add new counties
    county_ids.each do |county_id|
      county = County.find(county_id)
      self.counties << county
    end
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
    return if services_params.blank?

    services_params_ids = services_params.map { |service| service[:id] }.compact

    location.practice_types.each do |practice_type|
      unless services_params_ids.include?(practice_type.id)
        location.practice_types.delete(practice_type)
      end
    end

    services_params.each do |service_info|
      practice_type = PracticeType.find(service_info[:id])
      location.practice_types << practice_type unless location.practice_types.include?(practice_type)
    end
  end

  private

  def locations_required_unless_in_home_only
    if !in_home_only && locations.empty?
      errors.add(:locations, "are required for clinic-based providers")
    end
  end

  def validate_service_delivery_structure
    return unless service_delivery.present?

    unless service_delivery.is_a?(Hash) && service_delivery.key?('in_home') && service_delivery.key?('in_clinic')
      errors.add(:service_delivery, "must have 'in_home' and 'in_clinic' keys")
    end
  end
end
