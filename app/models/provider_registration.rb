require 'securerandom'

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

  # Normalize then derive category
  before_validation :normalize_service_types
  before_validation :set_category_from_service_types, if: -> { category.blank? }
  before_validation :set_default_status
  
  # Debug logging
  after_validation do
    Rails.logger.info(
      "[ProviderRegistration Debug] service_types=#{service_types.inspect} category=#{category.inspect} valid?=#{errors.empty?}"
    )
  end

  # Add support for multiple service types
  attribute :service_types, :string, array: true, default: []
  
  validates :service_types, presence: true, length: { minimum: 1, maximum: 5 }
  validate :validate_service_types_exist

  # Add idempotency key attribute
  attribute :idempotency_key, :string

  def can_be_approved?
    status == 'pending' && !is_processed
  end

  def can_be_rejected?
    status == 'pending' && !is_processed
  end

  def approve!(admin_user, notes = nil)
    return false unless can_be_approved?
    
    begin
      Rails.logger.info "Starting approval process for registration #{id}"
      
      # Create the provider (simplified)
      Rails.logger.info "Creating provider..."
      provider = create_provider_from_registration
      if provider
        Rails.logger.info "Provider created successfully: #{provider.id}"
      else
        Rails.logger.error "Provider creation failed"
        return false
      end
      
      # Update registration status - skip validations during status changes
      Rails.logger.info "Updating registration status..."
      update_columns(
        status: 'approved',
        reviewed_at: Time.current,
        reviewed_by_id: admin_user.id,
        admin_notes: notes,
        is_processed: true
      )
      
      # Reload the record to reflect changes
      reload
      Rails.logger.info "Registration status updated to approved"
      
      # Create secure user account for the provider
      Rails.logger.info "Creating user account..."
      user = create_provider_user_account(provider)
      if user
        Rails.logger.info "User account created successfully: #{user.id}"
      else
        Rails.logger.error "User account creation failed"
        return false
      end
      
      # Send approval email with login credentials
      Rails.logger.info "Sending approval email..."
      ProviderRegistrationMailer.approved_with_credentials(self, user).deliver_now
      Rails.logger.info "Approval email sent successfully"
      
      true
    rescue => e
      Rails.logger.error "Approval failed: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join(', ')}"
      errors.add(:base, "Failed to approve registration: #{e.message}")
      false
    end
  end

  def reject!(admin_user, reason = nil, notes = nil)
    return false unless can_be_rejected?
    
    # Skip validations during status changes to avoid issues with old data
    update_columns(
      status: 'rejected',
      reviewed_by_id: admin_user.id,
      reviewed_at: Time.current,
      rejection_reason: reason,
      admin_notes: notes,
      is_processed: true
    )
    
    # Reload the record to reflect changes
    reload
    
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

  def normalize_service_types
    # Ensure array
    case service_types
    when nil
      self.service_types = []
    when String
      self.service_types = [service_types]
    else
      self.service_types = service_types.to_a
    end

    # Downcase/slugify, remove blanks/dupes
    self.service_types = service_types
      .map { |s| s.to_s.strip }
      .reject(&:blank?)
      .map { |s| s.parameterize.underscore }
      .uniq
  end

  def set_category_from_service_types
    # If you have a ProviderCategory model with slugs, prefer the first valid one
    valid_slugs = ProviderCategory.active.pluck(:slug) rescue []
    chosen =
      if valid_slugs.present?
        service_types.find { |st| valid_slugs.include?(st) } || service_types.first
      else
        service_types.first
      end

    self.category = chosen if chosen.present?
  end

  def set_default_status
    self.status ||= 'pending'
  end

  def create_provider_user_account(provider)
    # Generate a secure random password
    password = SecureRandom.alphanumeric(12)
    
    # Create user account linked to the provider
    user = User.new(
      email: email,
      password: password,
      password_confirmation: password,
      provider_id: provider.id,
      role: 'user'  # Regular provider user, not admin
    )
    
    if user.save
      # Store the password temporarily for email (it will be hashed)
      user.instance_variable_set(:@plain_password, password)
      user
    else
      Rails.logger.error "Failed to create user account: #{user.errors.full_messages}"
      nil
    end
  end

  def create_provider_from_registration
    # Map submitted data to provider attributes (simplified)
    provider_attributes = {
      name: provider_name,
      email: email,
      category: category,
      status: :approved,
      in_home_only: true,  # Set to true to avoid location requirement
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
      update_columns(metadata: metadata.merge(provider_id: provider.id))
      provider
    else
      Rails.logger.error "Failed to create provider: #{provider.errors.full_messages}"
      nil
    end
  end

  def create_provider_attributes(provider)
    # Get the category fields for this provider type
    category_obj = ProviderCategory.find_by(slug: category)
    return unless category_obj

    category_obj.category_fields.each do |field|
      # Use slug for the key, but fall back to name if slug is nil (backward compatibility)
      key = field.slug || field.name.parameterize.underscore
      value = submitted_data[key] || submitted_data[field.name.parameterize.underscore]
      next unless value.present?

      # Special handling for insurance fields
      if field.name.downcase.include?('insurance')
        process_insurance_field(provider, field, value)
      else
        # Create provider attribute for non-insurance fields
        provider.provider_attributes.create!(
          category_field: field,
          value: value.is_a?(Array) ? value.join(', ') : value.to_s
        )
      end
    end
  end

  def process_insurance_field(provider, field, value)
    # Process insurance using the InsuranceService
    InsuranceService.link_insurances_to_provider(provider, value)
    
    # Also store the insurance names as a provider attribute for display
    insurance_names = value.is_a?(Array) ? value : [value]
    provider.provider_attributes.create!(
      category_field: field,
      value: insurance_names.join(', ')
    )
    
    Rails.logger.info "🔗 Processed insurance for #{provider.name}: #{insurance_names.join(', ')}"
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