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
    
    # Double-check to prevent race conditions
    reload
    return false unless can_be_approved?
    
    # Wrap everything in a transaction so we can rollback if anything fails
    ActiveRecord::Base.transaction do
      Rails.logger.info "Starting approval process for registration #{id}"
      
      # Create the provider (simplified)
      Rails.logger.info "Creating provider..."
      provider = create_provider_from_registration
      unless provider
        Rails.logger.error "Provider creation failed"
        raise StandardError, "Provider creation failed"
      end
      Rails.logger.info "Provider created successfully: #{provider.id}"
      
      # Create secure user account for the provider (check if user already exists)
      Rails.logger.info "Creating user account..."
      existing_user = User.find_by(email: email)
      if existing_user
        Rails.logger.info "User account already exists: #{existing_user.id}, linking to provider"
        existing_user.update(provider_id: provider.id) unless existing_user.provider_id == provider.id
        user = existing_user
        
        # If user already exists, we need to generate a new password for the email
        # (since we don't have the original password)
        # Use update_columns to bypass validations if password update fails
        new_password = SecureRandom.alphanumeric(12)
        begin
          user.password = new_password
          user.password_confirmation = new_password
          if user.save
            user.instance_variable_set(:@plain_password, new_password)
            Rails.logger.info "Generated new password for existing user (password reset)"
          else
            Rails.logger.warn "Failed to update password via save (validation errors): #{user.errors.full_messages.join(', ')}"
            # Try to update password directly (bypasses validations)
            # Note: This will hash the password automatically
            user.update_column(:encrypted_password, User.new(password: new_password).encrypted_password)
            user.instance_variable_set(:@plain_password, new_password)
            Rails.logger.info "Updated password via update_column (bypassed validations)"
          end
        rescue => password_error
          Rails.logger.error "Failed to update password: #{password_error.message}"
          # Continue anyway - we'll try to send email without password
        end
      else
        user = create_provider_user_account(provider)
        unless user
          Rails.logger.error "User account creation failed"
          raise StandardError, "User account creation failed"
        end
        Rails.logger.info "User account created successfully: #{user.id}"
      end
      
      # Update registration status - skip validations during status changes
      # Do this AFTER provider and user are created successfully
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
      
      # Send approval email with login credentials (non-blocking - don't fail approval if email fails)
      Rails.logger.info "Sending approval email to #{email}..."
      Rails.logger.info "User ID: #{user.id}, User Email: #{user.email}"
      Rails.logger.info "Password set: #{user.instance_variable_get(:@plain_password).present?}"
      
      begin
        mail = ProviderRegistrationMailer.approved_with_credentials(self, user)
        Rails.logger.info "Email prepared - To: #{mail.to}, Subject: #{mail.subject}"
        mail.deliver_now
        Rails.logger.info "✅ Approval email sent successfully to #{email}"
      rescue => email_error
        # Log email error but don't fail the approval - provider is already created
        Rails.logger.error "⚠️ Email delivery failed (but approval succeeded): #{email_error.class} - #{email_error.message}"
        Rails.logger.error "Email error backtrace: #{email_error.backtrace.first(5).join("\n")}"
        Rails.logger.error "Registration ID: #{id}, Provider ID: #{provider&.id}, User ID: #{user.id}"
        # Continue - approval is successful even if email fails
      end
      
      true
    end
  rescue => e
    Rails.logger.error "Approval failed: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
    errors.add(:base, "Failed to approve registration: #{e.message}")
    false
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
        .map { |s| s.parameterize }  # Use hyphens instead of underscores to match DB slugs
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
    # Get data from submitted_data, handling nested category structure
    data = get_submitted_data
    
    # Map submitted data to provider attributes (comprehensive)
    provider_attributes = {
      name: provider_name,
      email: email,
      category: category,
      status: :approved,
      
      # Basic business info - check both top level and nested category level
      website: data['website'] || '',
      phone: data['contact_phone'] || data['phone'] || '',
      
      # Service delivery options
      service_delivery: determine_service_delivery,
      
      # Service availability
      at_home_services: determine_at_home_services,
      in_clinic_services: determine_in_clinic_services,
      telehealth_services: determine_telehealth_services,
      
      # Accessibility and details
      spanish_speakers: data['spanish_speakers'] || 'Unknown',
      
      # Business details
      cost: data['pricing'] || data['cost'] || 'Contact us',
      waitlist: data['waitlist_status'] || data['waitlist'] || 'Contact us',
      min_age: extract_min_age(data),
      max_age: extract_max_age(data),
      
      # Default values for required fields
      in_home_only: true  # Set to true to avoid location requirement
    }

    # Create the provider
    provider = Provider.new(provider_attributes)
    
    if provider.save
      # Note: provider_id can be found via provider.provider_registrations association if needed
      # We skip storing in metadata since the column may not exist in all environments
      
      # Set up practice types from service types
      setup_practice_types(provider)
      
      # Set up insurance from registration data
      setup_insurance(provider)
      
      # Set up counties served (default to "Contact Us" if none specified)
      setup_counties_served(provider)
      
      # Create default location if needed
      create_default_location(provider)
      
      # Create provider attributes for category-specific fields
      create_provider_attributes(provider)
      
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

    data = get_submitted_data

    category_obj.category_fields.each do |field|
      # Use slug for the key, but fall back to name if slug is nil (backward compatibility)
      key = field.slug || field.name.parameterize.underscore
      value = data[key] || data[field.name.parameterize.underscore]
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
    data = get_submitted_data
    service_delivery = data['service_delivery'] || data['delivery_format']
    
    if service_delivery.is_a?(Array)
      {
        in_home: service_delivery.any? { |s| s.to_s.downcase.include?('home') || s.to_s.downcase.include?('in-person') },
        in_clinic: service_delivery.any? { |s| s.to_s.downcase.include?('clinic') || s.to_s.downcase.include?('in-person') },
        telehealth: service_delivery.any? { |s| s.to_s.downcase.include?('online') || s.to_s.downcase.include?('virtual') || s.to_s.downcase.include?('telehealth') }
      }
    elsif service_delivery.is_a?(String)
      service_delivery_lower = service_delivery.downcase
      {
        in_home: service_delivery_lower.include?('home') || service_delivery_lower.include?('in-person'),
        in_clinic: service_delivery_lower.include?('clinic') || service_delivery_lower.include?('in-person'),
        telehealth: service_delivery_lower.include?('online') || service_delivery_lower.include?('virtual') || service_delivery_lower.include?('telehealth')
      }
    else
      # Default based on category
      case category
      when 'aba_therapy', 'speech_therapy', 'occupational_therapy'
        { in_home: true, in_clinic: true, telehealth: true }
      when 'educational_programs'
        { in_home: false, in_clinic: false, telehealth: true } # Educational programs are typically online
      when 'dentists', 'orthodontists'
        { in_home: false, in_clinic: true, telehealth: false }
      when 'barbers_hair'
        { in_home: true, in_clinic: true, telehealth: false }
      else
        { in_home: false, in_clinic: true, telehealth: false }
      end
    end
  end

  def determine_at_home_services
    service_delivery = determine_service_delivery
    service_delivery[:in_home] ? 'Yes' : 'No'
  end

  def determine_in_clinic_services
    service_delivery = determine_service_delivery
    service_delivery[:in_clinic] ? 'Yes' : 'No'
  end

  def determine_telehealth_services
    service_delivery = determine_service_delivery
    service_delivery[:telehealth] ? 'Yes' : 'No'
  end

  def setup_practice_types(provider)
    return if service_types.blank?
    
    service_types.each do |service_type|
      # Map service type to practice type
      practice_type = case service_type
      when 'aba_therapy'
        PracticeType.find_by(name: 'ABA Therapy')
      when 'speech_therapy'
        PracticeType.find_by(name: 'Speech Therapy')
      when 'occupational_therapy'
        PracticeType.find_by(name: 'Occupational Therapy')
      when 'autism_evaluation'
        PracticeType.find_by(name: 'Autism Evaluation')
      when 'educational_programs'
        # Educational Programs is a category, not a practice type
        # Try to find or create a practice type for it
        PracticeType.find_or_create_by(name: 'Educational Programs')
      else
        PracticeType.find_by(name: service_type.titleize) || 
        PracticeType.find_or_create_by(name: service_type.titleize)
      end
      
      if practice_type
        provider.practice_types << practice_type unless provider.practice_types.include?(practice_type)
        Rails.logger.info "Added practice type: #{practice_type.name} to provider #{provider.id}"
      else
        Rails.logger.warn "Could not find or create practice type for: #{service_type}"
      end
    end
  end

  def setup_insurance(provider)
    data = get_submitted_data
    insurance_data = data['insurance'] || data['insurance_preferences']
    return if insurance_data.blank?
    
    # Process insurance using the InsuranceService
    InsuranceService.link_insurances_to_provider(provider, insurance_data)
    Rails.logger.info "Set up insurance for provider #{provider.id}: #{insurance_data}"
  end

  def setup_counties_served(provider)
    data = get_submitted_data
    counties_data = data['counties'] || data['counties_served'] || data['geographic_coverage'] || data['service_areas']
    
    if counties_data.present?
      # Normalize to array - handle both string and array inputs
      counties_array = if counties_data.is_a?(String)
        # If it's a string like "Utah", try to find counties in that state
        # Or treat it as a single county name
        [counties_data]
      elsif counties_data.is_a?(Array)
        counties_data
      else
        # If it's something else (Hash, etc.), try to convert
        [counties_data]
      end
      
      # Process specific counties if provided
      counties_array.each do |county_info|
        if county_info.is_a?(Hash) && county_info['name'].present?
          county = County.find_by(name: county_info['name'])
          provider.counties << county if county
        elsif county_info.is_a?(String)
          # Try to find county by name
          county = County.find_by(name: county_info)
          if county
            provider.counties << county unless provider.counties.include?(county)
          else
            # If county not found by name, it might be a state name
            # Try to find all counties in that state
            state = State.find_by(name: county_info)
            if state
              state.counties.each do |state_county|
                provider.counties << state_county unless provider.counties.include?(state_county)
              end
              Rails.logger.info "Added all counties from state '#{county_info}' to provider #{provider.id}"
            else
              Rails.logger.warn "Could not find county or state: #{county_info}"
            end
          end
        end
      end
    end
    
    # If no counties specified, add "Contact Us" county
    if provider.counties.empty?
      contact_county = County.find_by(name: 'Contact Us')
      provider.counties << contact_county if contact_county
      Rails.logger.info "Added default 'Contact Us' county for provider #{provider.id}"
    end
    
    Rails.logger.info "Set up counties for provider #{provider.id}: #{provider.counties.pluck(:name).join(', ')}"
  end

  def service_delivery_includes_clinic?
    delivery = determine_service_delivery
    delivery[:in_clinic] == true
  end

  def create_default_location(provider)
    # Create a basic location if we have address info
    data = get_submitted_data
    location_data = data['service_areas'] || data['geographic_coverage']
    primary_address = data['primary_address'] || {}
    
    # Extract waitlist values from submitted data (can be at top level or nested)
    in_home_waitlist = data['in_home_waitlist'] || primary_address['in_home_waitlist']
    in_clinic_waitlist = data['in_clinic_waitlist'] || primary_address['in_clinic_waitlist']
    
    # Normalize waitlist values to valid options (default to "Contact for availability" if not provided)
    in_home_waitlist = normalize_waitlist_value(in_home_waitlist) || "Contact for availability"
    in_clinic_waitlist = normalize_waitlist_value(in_clinic_waitlist) || "Contact for availability"
    
    location_attrs = {
      in_home_waitlist: in_home_waitlist,
      in_clinic_waitlist: in_clinic_waitlist
    }
    
    if primary_address.present? && primary_address['street'].present?
      provider.locations.create!(
        location_attrs.merge(
          name: "#{provider_name} - Main Office",
          address_1: primary_address['street'] || primary_address['address_1'] || "Contact for address",
          address_2: primary_address['suite'] || primary_address['address_2'] || '',
          city: primary_address['city'] || "Contact for location",
          state: primary_address['state'] || "Contact for location",
          zip: primary_address['zip'] || "Contact for location",
          phone: primary_address['phone'] || data['contact_phone'] || provider.phone
        )
      )
    elsif location_data.present?
      provider.locations.create!(
        location_attrs.merge(
          name: "#{provider_name} - Main Office",
          address_1: "Contact for address", # We don't have full address from registration
          city: "Contact for location",
          state: "Contact for location",
          zip: "Contact for location",
          phone: data['contact_phone'] || provider.phone
        )
      )
    end
  end
  
  # Normalize waitlist value to valid Location::WAITLIST_OPTIONS
  # Same logic as Provider model for consistency
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
      Rails.logger.warn "⚠️ Invalid waitlist value in registration '#{value}', defaulting to 'Contact for availability'"
      "Contact for availability"
    end
  end

  # Helper method to get submitted_data, handling nested category structure
  def get_submitted_data
    # Check if data is nested under category key (e.g., submitted_data['educational_programs'])
    if submitted_data.is_a?(Hash) && submitted_data[category].is_a?(Hash)
      # Merge top-level and category-specific data, with category data taking precedence
      (submitted_data.except(category) || {}).merge(submitted_data[category] || {})
    else
      submitted_data || {}
    end
  end

  def extract_min_age(data)
    age_groups = data['age_groups'] || []
    return nil if age_groups.blank?
    
    # Extract minimum age from age groups like "4-5 years", "Preschool (3-5)", etc.
    min_ages = age_groups.map do |group|
      if group.is_a?(String)
        # Try to extract numbers from strings like "4-5 years", "Preschool (3-5)", "3-5"
        numbers = group.scan(/\d+/).map(&:to_i)
        numbers.min if numbers.any?
      end
    end.compact
    
    min_ages.min
  end

  def extract_max_age(data)
    age_groups = data['age_groups'] || []
    return nil if age_groups.blank?
    
    # Extract maximum age from age groups
    max_ages = age_groups.map do |group|
      if group.is_a?(String)
        # Try to extract numbers from strings like "4-5 years", "Preschool (3-5)", "3-5"
        numbers = group.scan(/\d+/).map(&:to_i)
        numbers.max if numbers.any?
      end
    end.compact
    
    max_ages.max
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