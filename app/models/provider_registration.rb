class ProviderRegistration < ApplicationRecord
  belongs_to :reviewed_by, class_name: 'User', optional: true


  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :provider_name, presence: true
  validates :category, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :unprocessed, -> { where(is_processed: false) }

  before_validation :set_default_status

  # Add support for multiple service types
  attribute :service_types, :string, array: true, default: []
  
  validates :service_types, presence: true, length: { minimum: 1, maximum: 5 }
  validate :validate_service_types_exist

  def can_be_approved?
    status == 'pending' && !is_processed
  end

  def can_be_rejected?
    status == 'pending' && !is_processed
  end

  def approve!
    return false unless can_be_approved?
    
    transaction do
      # Create the provider
      provider = create_provider_from_registration
      
      # Add all service types
      service_types.each_with_index do |service_type_slug, index|
        category = ProviderCategory.find_by(slug: service_type_slug)
        next unless category
        
        # First service type becomes primary
        is_primary = (index == 0)
        provider.add_service_type(category, is_primary: is_primary)
      end
      
      # Create provider attributes for each service type
      create_provider_attributes(provider)
      
      # Create default location if needed
      create_default_location(provider)
      
      # Update registration status
      update!(
        status: 'approved',
        reviewed_at: Time.current,
        reviewed_by: User.current,
        is_processed: true
      )
      
      # Send approval email
      ProviderRegistrationMailer.approved(self).deliver_now
      
      true
    rescue => e
      errors.add(:base, "Failed to approve registration: #{e.message}")
      false
    end
  end

  def reject!(admin_user, reason = nil, notes = nil)
    return false unless can_be_rejected?
    
    update!(
      status: 'rejected',
      reviewed_by: admin_user,
      reviewed_at: Time.current,
      rejection_reason: reason,
      admin_notes: notes,
      is_processed: true
    )
    
    # Send rejection email to provider
    ProviderRegistrationMailer.rejected(self).deliver_later
  end

  def provider_created?
    metadata&.dig('provider_id').present?
  end

  def provider
    return nil unless provider_created?
    Provider.find_by(id: metadata['provider_id'])
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end

  def create_provider_from_registration
    # Map submitted data to provider attributes
    provider_attributes = {
      name: provider_name,
      email: email,
      category: category,
      status: :approved,
      in_home_only: determine_in_home_only,
      service_delivery: determine_service_delivery,
      # Set default values for required fields
      website: submitted_data['website'] || '',
      phone: submitted_data['contact_phone'] || '',
      spanish_speakers: 'Unknown',
      telehealth_services: 'Unknown',
      at_home_services: 'Unknown',
      in_clinic_services: 'Unknown'
    }

    # Create the provider
    provider = Provider.new(provider_attributes)
    
    if provider.save
      # Store the provider ID in metadata for reference
      update!(metadata: metadata.merge(provider_id: provider.id))
      
      # Create provider attributes from submitted data
      create_provider_attributes(provider)
      
      # Create a basic location if service delivery includes in-clinic
      if service_delivery_includes_clinic?
        create_default_location(provider)
      end
      
      puts "✅ Created provider: #{provider.name} (ID: #{provider.id})"
    else
      puts "❌ Failed to create provider: #{provider.errors.full_messages}"
      # Store error in metadata for admin review
      update!(metadata: metadata.merge(provider_creation_error: provider.errors.full_messages))
    end
  end

  def create_provider_attributes(provider)
    # Get the category fields for this provider type
    category_obj = ProviderCategory.find_by(slug: category)
    return unless category_obj

    category_obj.category_fields.each do |field|
      value = submitted_data[field.name.parameterize.underscore]
      next unless value.present?

      # Create provider attribute
      provider.provider_attributes.create!(
        category_field: field,
        value: value.is_a?(Array) ? value.join(', ') : value.to_s
      )
    end
  end

  def determine_in_home_only
    # Check if the provider offers in-home services
    service_delivery = submitted_data['service_delivery']
    return true if service_delivery.is_a?(Array) && service_delivery.include?('Home Visits')
    return true if service_delivery.is_a?(String) && service_delivery.include?('Home Visits')
    
    # Default based on category
    case category
    when 'aba_therapy', 'speech_therapy', 'occupational_therapy'
      false # These typically offer both in-home and clinic
    when 'dentists', 'orthodontists', 'barbers_hair'
      false # These are typically clinic-based
    else
      false
    end
  end

  def determine_service_delivery
    service_delivery = submitted_data['service_delivery']
    
    if service_delivery.is_a?(Array)
      {
        in_home: service_delivery.include?('Home Visits'),
        in_clinic: service_delivery.include?('Clinic-Based') || service_delivery.include?('In-Person'),
        telehealth: service_delivery.include?('Teletherapy') || service_delivery.include?('Virtual/Online')
      }
    elsif service_delivery.is_a?(String)
      {
        in_home: service_delivery.include?('Home Visits'),
        in_clinic: service_delivery.include?('Clinic-Based') || service_delivery.include?('In-Person'),
        telehealth: service_delivery.include?('Teletherapy') || service_delivery.include?('Virtual/Online')
      }
    else
      # Default based on category
      case category
      when 'aba_therapy', 'speech_therapy', 'occupational_therapy'
        { in_home: true, in_clinic: true, telehealth: true }
      when 'dentists', 'orthodontists'
        { in_home: false, in_clinic: true, telehealth: false }
      when 'barbers_hair'
        { in_home: true, in_clinic: true, telehealth: false }
      else
        { in_home: false, in_clinic: true, telehealth: false }
      end
    end
  end

  def service_delivery_includes_clinic?
    delivery = determine_service_delivery
    delivery[:in_clinic] == true
  end

  def create_default_location(provider)
    # Create a basic location if we have address info
    location_data = submitted_data['service_areas'] || submitted_data['geographic_coverage']
    
    if location_data.present?
      provider.locations.create!(
        name: "#{provider_name} - Main Office",
        address_1: "Contact for address", # We don't have full address from registration
        city: "Contact for location",
        state: "Contact for location",
        zip: "Contact for location",
        phone: submitted_data['contact_phone'] || provider.phone
      )
    end
  end

  def validate_service_types_exist
    return if service_types.blank?
    
    service_types.each do |service_type|
      unless ProviderCategory.exists?(slug: service_type)
        errors.add(:service_types, "contains invalid service type: #{service_type}")
      end
    end
  end
end 