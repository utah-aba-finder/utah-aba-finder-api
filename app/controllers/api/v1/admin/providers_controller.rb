require 'securerandom'

class Api::V1::Admin::ProvidersController < Api::V1::Admin::BaseController
  include Pagy::Backend
  
  def index
    # Add pagination to prevent memory issues
    per_page = params[:per_page]&.to_i || 25  # Reduced default from 50 to 25
    per_page = [per_page, 50].min # Reduced max from 100 to 50
    
    # Use select to only load necessary columns
    providers_query = Provider.select(:id, :name, :email, :status, :created_at, :updated_at)
                             .includes(:counties, :practice_types, :locations, :insurances)
                             .order(:name)
    
    @pagy, providers = pagy(providers_query, items: per_page)
    
    # Log memory usage
    Rails.logger.info "📊 Memory usage - Providers loaded: #{providers.count}, Per page: #{per_page}"
    
    render json: {
      data: ProviderSerializer.format_providers(providers),
      meta: {
        waitlist_options: Location::WAITLIST_OPTIONS,
        pagination: {
          current_page: @pagy.page,
          total_pages: @pagy.pages,
          total_count: @pagy.count,
          per_page: @pagy.items
        }
      }
    }
  end

  def create
    # Get attributes for nested data processing
    attributes = get_request_attributes
    
    # Create provider with all necessary setup
    provider = Provider.new(admin_provider_params)
    
    # Set default status to approved for admin-created providers
    provider.status = :approved
    
    # Set default service delivery if not provided
    provider.service_delivery ||= { "in_home" => true, "in_clinic" => false }
    
    # Set default in_home_only to true to avoid location requirement initially
    provider.in_home_only = true if provider.in_home_only.nil?
    
    # Set default category if not provided (required for validation)
    provider.category ||= 'aba_therapy' if provider.category.blank?
    
    # If this is a clinic-based provider (in_home_only = false), we need to create locations first
    # Exception: telehealth-only providers don't need physical locations
    if !provider.in_home_only && !provider.telehealth_only? && attributes[:locations].present?
      # Temporarily set in_home_only to true to bypass validation
      provider.in_home_only = true
    end
    
    if provider.save
      # Create user account for the provider
      user = create_provider_user_account(provider)
      
      # Set up practice types if provided
      if attributes[:provider_type].present?
        provider.create_practice_types(attributes[:provider_type])
      end
      
      # Set up locations if provided
      if attributes[:locations].present?
        update_locations(provider, attributes[:locations])
        
        # If this was a clinic-based provider, update in_home_only to false after locations are created
        if !admin_provider_params[:in_home_only]
          provider.update!(in_home_only: false)
        end
      end
      
      # Set up counties served if provided
      if attributes[:counties_served].present?
        update_counties_served(provider, attributes[:counties_served])
      end
      
      # Set up insurance if provided
      if attributes[:insurance].present?
        setup_insurance(provider, attributes[:insurance])
      end
      
      # Send welcome email to provider
      if user
        send_welcome_email(provider, user)
      end
      
      render json: ProviderSerializer.format_providers([provider]), status: :created
    else
      Rails.logger.error "❌ Admin create failed - Errors: #{provider.errors.full_messages}"
      Rails.logger.error "❌ Admin create failed - Provider attributes: #{provider.attributes.inspect}"
      Rails.logger.error "❌ Admin create failed - Params: #{params.inspect}"
      render json: { 
        errors: provider.errors.full_messages,
        details: provider.errors.details,
        attributes: provider.attributes
      }, status: :unprocessable_entity
    end
  end

  def update
    provider = Provider.find(params[:id])

    # Debug: Log all incoming params to see what the frontend is sending
    Rails.logger.info "🔍 Admin update - ALL PARAMS: #{params.inspect}"
    Rails.logger.info "🔍 Admin update - Data structure: #{params[:data].inspect}"
    if params[:data]&.first&.dig(:attributes)
      Rails.logger.info "🔍 Admin update - Attributes keys: #{params[:data].first[:attributes].keys.inspect}"
    end

    # Handle practice types separately if provided
    practice_type_params = nil
    if params[:data]&.first&.dig(:attributes, :provider_type)&.present?
      practice_type_params = params[:data].first[:attributes][:provider_type]
    elsif params[:provider_type].present?
      practice_type_params = params[:provider_type]
    end

    # Handle locations separately if provided
    locations_params = nil
    if params[:data]&.first&.dig(:attributes, :locations)&.present?
      locations_params = params[:data].first[:attributes][:locations]
    elsif params[:locations].present?
      locations_params = params[:locations]
    end

    # Handle counties served separately if provided
    counties_params = nil
    if params[:data]&.first&.dig(:attributes, :counties_served)&.present?
      counties_params = params[:data].first[:attributes][:counties_served]
    elsif params[:counties_served].present?
      counties_params = params[:counties_served]
    end

    # Handle states separately if provided
    states_params = nil
    if params[:data]&.first&.dig(:attributes, :states)&.present?
      states_params = params[:data].first[:attributes][:states]
    elsif params[:states].present?
      states_params = params[:states]
    end

    # Handle provider_attributes (category-specific fields) separately if provided
    provider_attributes_params = nil
    if params[:data]&.first&.dig(:attributes, :provider_attributes)&.present?
      provider_attributes_params = params[:data].first[:attributes][:provider_attributes]
      Rails.logger.info "🔍 Admin update - Found provider_attributes in data[0][attributes]: #{provider_attributes_params.inspect}"
    elsif params[:data]&.first&.dig(:attributes, "provider_attributes")&.present?
      provider_attributes_params = params[:data].first[:attributes]["provider_attributes"]
      Rails.logger.info "🔍 Admin update - Found provider_attributes (string key) in data[0][attributes]: #{provider_attributes_params.inspect}"
    elsif params[:provider_attributes].present?
      provider_attributes_params = params[:provider_attributes]
      Rails.logger.info "🔍 Admin update - Found provider_attributes at top level: #{provider_attributes_params.inspect}"
    else
      Rails.logger.warn "⚠️ Admin update - No provider_attributes found in request"
    end

    # Debug logging
    Rails.logger.info "🔍 Admin update - Provider ID: #{provider.id}"
    Rails.logger.info "🔍 Admin update - Basic Params: #{admin_provider_params.inspect}"
    Rails.logger.info "🔍 Admin update - Locations Params: #{locations_params.inspect}"
    Rails.logger.info "🔍 Admin update - Counties Params: #{counties_params.inspect}"
    Rails.logger.info "🔍 Admin update - States Params: #{states_params.inspect}"
    Rails.logger.info "🔍 Admin update - Provider Attributes Params: #{provider_attributes_params.inspect}"
    Rails.logger.info "🔍 Admin update - Current category: #{provider.category}"

    # Create locations FIRST to satisfy validation
    if locations_params.present?
      update_locations(provider, locations_params)
    end

    # Now update the provider (validation should pass since locations exist)
    if provider.update(admin_provider_params)
      # Update practice types if provided
      if practice_type_params.present?
        provider.update_practice_types(practice_type_params)
      end

      # Update counties served if provided
      if counties_params.present?
        update_counties_served(provider, counties_params)
      end

      # Update provider_attributes (category-specific fields) if provided
      if provider_attributes_params.present?
        update_provider_attributes(provider, provider_attributes_params)
      end

      provider.touch # Ensure updated_at is updated
      render json: ProviderSerializer.format_providers([provider])
    else
      Rails.logger.error "❌ Admin update failed - Errors: #{provider.errors.full_messages}"
      render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def create_provider_user_account(provider)
    # Check if user already exists with this email
    existing_user = User.find_by(email: provider.email)
    if existing_user
      Rails.logger.info "✅ User already exists for provider #{provider.id}: #{existing_user.email}"
      # Update the existing user to link to this provider
      existing_user.update!(provider_id: provider.id) if existing_user.provider_id != provider.id
      return existing_user
    end
    
    # Generate a secure random password
    password = SecureRandom.alphanumeric(12)
    
    # Create user account linked to the provider
    user = User.new(
      email: provider.email,
      password: password,
      password_confirmation: password,
      provider_id: provider.id,
      role: 'user'  # Regular provider user, not admin
    )
    
    if user.save
      # Store the password temporarily for email (it will be hashed)
      user.instance_variable_set(:@plain_password, password)
      Rails.logger.info "✅ Created user account for provider #{provider.id}: #{user.email}"
      user
    else
      Rails.logger.error "❌ Failed to create user account: #{user.errors.full_messages}"
      nil
    end
  end

  def create_locations(provider, locations_data)
    locations_data.each do |location_info|
      location = provider.locations.build(
        name: location_info[:name] || location_info['name'],
        address_1: location_info[:address_1] || location_info['address_1'],
        address_2: location_info[:address_2] || location_info['address_2'],
        city: location_info[:city] || location_info['city'],
        state: location_info[:state] || location_info['state'],
        zip: location_info[:zip] || location_info['zip'],
        phone: location_info[:phone] || location_info['phone'],
        in_home_waitlist: location_info[:in_home_waitlist] || location_info['in_home_waitlist'] || 'Contact us',
        in_clinic_waitlist: location_info[:in_clinic_waitlist] || location_info['in_clinic_waitlist'] || 'Contact us'
      )
      
      if location.save
        Rails.logger.info "✅ Created location #{location.id} for provider #{provider.id}"
        
        # Handle services for this location if provided
        if location_info[:services].present? || location_info['services'].present?
          services = location_info[:services] || location_info['services']
          update_location_services(location, services)
        end
      else
        Rails.logger.error "❌ Failed to create location: #{location.errors.full_messages}"
      end
    end
  end

  def setup_insurance(provider, insurance_data)
    insurance_data.each do |insurance_info|
      insurance_id = insurance_info[:id] || insurance_info['id']
      if insurance_id.present?
        insurance = Insurance.find_by(id: insurance_id)
        if insurance
          provider_insurance = provider.provider_insurances.find_or_initialize_by(insurance: insurance)
          provider_insurance.accepted = true
          provider_insurance.save!
          Rails.logger.info "✅ Added insurance #{insurance.name} for provider #{provider.id}"
        end
      end
    end
  end

  def send_welcome_email(provider, user)
    begin
      # Send welcome email with login credentials (synchronous for immediate delivery)
      ProviderRegistrationMailer.admin_created_provider(provider, user).deliver_now
      Rails.logger.info "✅ Welcome email sent to #{provider.email}"
    rescue => e
      Rails.logger.error "❌ Failed to send welcome email: #{e.message}"
    end
  end

  def update_counties_served(provider, counties_data)
    Rails.logger.info "🔍 Updating counties for provider #{provider.id}: #{counties_data.inspect}"
    
    # Extract and deduplicate county IDs
    county_ids = counties_data.map do |county_info|
      county_info[:county_id] || county_info["county_id"]
    end.compact.uniq
    
    Rails.logger.info "🔍 Deduplicated county IDs: #{county_ids.inspect}"
    
    # Safer deletion with sanitization and no default_scope
    CountiesProvider.unscoped.where(provider_id: provider.id).delete_all
    
    # Recreate (also bypass default_scope to prevent the WHERE "" IS NULL filter)
    # Use find_or_create_by to avoid duplicate key errors
    county_ids.each do |county_id|
      CountiesProvider.unscoped.find_or_create_by!(
        provider_id: provider.id,
        county_id: county_id
      )
      Rails.logger.info "✅ Added county #{county_id} for provider #{provider.id}"
    end
  end

  def update_provider_attributes(provider, attributes_data)
    # attributes_data should be a hash like: { "field_name" => "value", "another_field" => "value" }
    # Handle ActionController::Parameters by converting to hash
    if attributes_data.is_a?(ActionController::Parameters)
      attributes_data = attributes_data.to_unsafe_h
    end
    return unless attributes_data.is_a?(Hash)

    Rails.logger.info "🔍 Updating provider_attributes for provider #{provider.id}: #{attributes_data.inspect}"

    attributes_data.each do |field_name, value|
      # Find the category field by name (case-insensitive)
      field = provider.category_fields.find_by('LOWER(name) = LOWER(?)', field_name)
      unless field
        Rails.logger.warn "⚠️ Category field '#{field_name}' not found for provider #{provider.id} (category: #{provider.category})"
        next
      end

      # Handle array values (for multi_select fields)
      if value.is_a?(Array)
        # Join array values with comma and space, preserving spaces within values
        processed_value = value.map(&:to_s).map(&:strip).reject(&:blank?).join(', ')
      else
        # For text/textarea fields, preserve spaces and trim only leading/trailing whitespace
        processed_value = value.to_s.strip
      end

      # Use set_attribute_value which handles find_or_initialize_by
      if provider.set_attribute_value(field_name, processed_value)
        Rails.logger.info "✅ Updated attribute '#{field_name}' for provider #{provider.id}: #{processed_value}"
      else
        Rails.logger.error "❌ Failed to update attribute '#{field_name}' for provider #{provider.id}"
      end
    end
  end

  def update_locations(provider, locations_data)
    Rails.logger.info "🔍 DEBUG: update_locations method called with provider_id: #{provider.id}"
    Rails.logger.info "🔍 DEBUG: locations_data class: #{locations_data.class}"
    Rails.logger.info "🔍 DEBUG: locations_data first item class: #{locations_data.first.class if locations_data.any?}"
    Rails.logger.info "🔍 DEBUG: locations_data first item permitted?: #{locations_data.first.permitted? if locations_data.any?}"
    
    Rails.logger.info "🔍 Updating locations for provider #{provider.id}: #{locations_data.inspect}"
    
    # Clear existing locations
    provider.locations.destroy_all
    
    # Create new locations
    locations_data.each do |location_info|
      # For telehealth-only providers, only require phone number
      # For other providers, require address or city
      if provider.telehealth_only?
        next unless location_info[:phone].present?
      else
        next unless location_info[:address_1].present? || location_info[:city].present?
      end
      
      Rails.logger.info "🔍 DEBUG: Processing location_info: #{location_info.inspect}"
      Rails.logger.info "🔍 DEBUG: location_info class: #{location_info.class}"
      Rails.logger.info "🔍 DEBUG: location_info permitted?: #{location_info.permitted?}"
      
      # Permit the location parameters so they can be accessed during validation
      permitted_location_info = location_info.permit(
        :name, :address_1, :address_2, :city, :state, :zip, :phone,
        :in_home_waitlist, :in_clinic_waitlist, services: [:id, :name]
      )
      
      Rails.logger.info "🔍 DEBUG: permitted_location_info: #{permitted_location_info.inspect}"
      Rails.logger.info "🔍 DEBUG: permitted_location_info permitted?: #{permitted_location_info.permitted?}"
      Rails.logger.info "🔍 DEBUG: in_home_waitlist value: #{permitted_location_info[:in_home_waitlist]}"
      Rails.logger.info "🔍 DEBUG: in_clinic_waitlist value: #{permitted_location_info[:in_clinic_waitlist]}"
      
      # Determine if this location provides in-home services
      has_in_home_services = permitted_location_info[:services]&.any? { |service| service[:name]&.downcase&.include?('home') || service[:name]&.downcase&.include?('in-home') }
      
      # Set appropriate waitlist defaults ONLY if not explicitly provided by frontend
      in_home_waitlist_default = if has_in_home_services
                                   "Contact for availability"
                                 else
                                   "No in-home services available at this location"
                                 end
      
      # Use frontend values if provided, otherwise use intelligent defaults
      # Ensure values are properly trimmed and match valid options
      in_home_waitlist = if permitted_location_info[:in_home_waitlist].present?
                           permitted_location_info[:in_home_waitlist].to_s.strip
                         else
                           in_home_waitlist_default
                         end
      
      in_clinic_waitlist = if permitted_location_info[:in_clinic_waitlist].present?
                             permitted_location_info[:in_clinic_waitlist].to_s.strip
                           else
                             "Contact for availability"
                           end
      
      # Validate that the waitlist values are in the allowed options
      unless Location::WAITLIST_OPTIONS.include?(in_home_waitlist)
        Rails.logger.warn "⚠️ Invalid in_home_waitlist value: '#{in_home_waitlist}', using default"
        in_home_waitlist = in_home_waitlist_default
      end
      
      unless Location::WAITLIST_OPTIONS.include?(in_clinic_waitlist)
        Rails.logger.warn "⚠️ Invalid in_clinic_waitlist value: '#{in_clinic_waitlist}', using default"
        in_clinic_waitlist = "Contact for availability"
      end
      
      Rails.logger.info "🔍 DEBUG: Final in_home_waitlist: #{in_home_waitlist}"
      Rails.logger.info "🔍 DEBUG: Final in_clinic_waitlist: #{in_clinic_waitlist}"
      
      # Debug: Check exact string comparison
      Rails.logger.info "🔍 DEBUG: in_home_waitlist bytes: #{in_home_waitlist.bytes.inspect}"
      Rails.logger.info "🔍 DEBUG: in_home_waitlist length: #{in_home_waitlist.length}"
      Rails.logger.info "🔍 DEBUG: in_home_waitlist in WAITLIST_OPTIONS?: #{Location::WAITLIST_OPTIONS.include?(in_home_waitlist)}"
      Rails.logger.info "🔍 DEBUG: WAITLIST_OPTIONS: #{Location::WAITLIST_OPTIONS.inspect}"
      
      # For telehealth-only providers, set default virtual location name if not provided
      location_name = permitted_location_info[:name]
      if provider.telehealth_only? && location_name.blank?
        location_name = "Virtual Location"
      end
      
      location = provider.locations.build(
        name: location_name,
        address_1: permitted_location_info[:address_1],
        address_2: permitted_location_info[:address_2],
        city: permitted_location_info[:city],
        state: permitted_location_info[:state],
        zip: permitted_location_info[:zip],
        phone: permitted_location_info[:phone],
        in_home_waitlist: in_home_waitlist,
        in_clinic_waitlist: in_clinic_waitlist
      )
      
      if location.save
        Rails.logger.info "✅ Added location #{location.id} for provider #{provider.id}"
        
        # Handle services for this location if provided
        if permitted_location_info[:services].present?
          update_location_services(location, permitted_location_info[:services])
        end
      else
        Rails.logger.error "❌ Failed to save location: #{location.errors.full_messages}"
      end
    end
  end

  def update_provider_attributes(provider, attributes_data)
    # attributes_data should be a hash like: { "field_name" => "value", "another_field" => "value" }
    # Handle ActionController::Parameters by converting to hash
    if attributes_data.is_a?(ActionController::Parameters)
      attributes_data = attributes_data.to_unsafe_h
    end
    return unless attributes_data.is_a?(Hash)

    Rails.logger.info "🔍 Updating provider_attributes for provider #{provider.id}: #{attributes_data.inspect}"

    attributes_data.each do |field_name, value|
      # Find the category field by name (case-insensitive)
      field = provider.category_fields.find_by('LOWER(name) = LOWER(?)', field_name)
      unless field
        Rails.logger.warn "⚠️ Category field '#{field_name}' not found for provider #{provider.id} (category: #{provider.category})"
        next
      end

      # Handle array values (for multi_select fields)
      if value.is_a?(Array)
        # Join array values with comma and space, preserving spaces within values
        processed_value = value.map(&:to_s).map(&:strip).reject(&:blank?).join(', ')
      else
        # For text/textarea fields, preserve spaces and trim only leading/trailing whitespace
        processed_value = value.to_s.strip
      end

      # Use set_attribute_value which handles find_or_initialize_by
      if provider.set_attribute_value(field_name, processed_value)
        Rails.logger.info "✅ Updated attribute '#{field_name}' for provider #{provider.id}: #{processed_value}"
      else
        Rails.logger.error "❌ Failed to update attribute '#{field_name}' for provider #{provider.id}"
      end
    end
  end

  def update_location_services(location, services_data)
    Rails.logger.info "🔍 Updating services for location #{location.id}: #{services_data.inspect}"
    Rails.logger.info "🔍 DEBUG: services_data class: #{services_data.class}"
    Rails.logger.info "🔍 DEBUG: services_data first item: #{services_data.first.inspect if services_data.any?}"
    
    # Clear existing services for this location
    Rails.logger.info "🔍 DEBUG: Clearing existing practice_types for location #{location.id}"
    location.practice_types.clear
    Rails.logger.info "🔍 DEBUG: After clear, practice_types count: #{location.practice_types.count}"
    
    # Add new services
    services_data.each do |service_info|
      Rails.logger.info "🔍 DEBUG: Processing service_info: #{service_info.inspect}"
      Rails.logger.info "🔍 DEBUG: service_info class: #{service_info.class}"
      Rails.logger.info "🔍 DEBUG: service_info[:id]: #{service_info[:id]}"
      Rails.logger.info "🔍 DEBUG: service_info[:name]: #{service_info[:name]}"
      
      practice_type = nil
      
      # Try to find by ID first
      if service_info[:id].present?
        practice_type = PracticeType.find_by(id: service_info[:id])
        Rails.logger.info "🔍 DEBUG: Found practice_type by ID: #{practice_type.inspect}"
      end
      
      # If ID lookup failed, try by name
      if practice_type.nil? && service_info[:name].present?
        practice_type = PracticeType.find_by(name: service_info[:name])
        Rails.logger.info "🔍 DEBUG: Found practice_type by name: #{practice_type.inspect}"
      end
      
      # Add the service if found
      if practice_type
        location.practice_types << practice_type
        Rails.logger.info "✅ Added service #{practice_type.name} to location #{location.id}"
      else
        Rails.logger.warn "⚠️ Practice type not found by ID (#{service_info[:id]}) or name (#{service_info[:name]})"
      end
    end
    
    Rails.logger.info "🔍 DEBUG: Final practice_types count for location #{location.id}: #{location.practice_types.count}"
    Rails.logger.info "🔍 DEBUG: Final practice_types: #{location.practice_types.map(&:name)}"
  end

  def get_request_attributes
    # Handle both data array format and direct attributes format
    if params[:data].present? && params[:data].is_a?(Array)
      # Format: { data: [{ attributes: {...} }] }
      params[:data].first[:attributes]
    elsif params[:data].present? && params[:data][:attributes].present?
      # Format: { data: { attributes: {...} } }
      params[:data][:attributes]
    elsif params[:attributes].present?
      # Format: { attributes: {...} }
      params[:attributes]
    else
      # Fallback to direct params
      params
    end
  end

  def admin_provider_params
    # Handle both data array format and direct attributes format
    if params[:data].present? && params[:data].is_a?(Array)
      # Format: { data: [{ attributes: {...} }] }
      attributes = params.require(:data).first[:attributes]
    elsif params[:data].present? && params[:data][:attributes].present?
      # Format: { data: { attributes: {...} } }
      attributes = params.require(:data)[:attributes]
    elsif params[:attributes].present?
      # Format: { attributes: {...} }
      attributes = params[:attributes]
    else
      # Fallback to direct params
      attributes = params
    end
    
    # Filter out logo if it's just a URL string (not a file upload)
    if attributes[:logo].present? && attributes[:logo].is_a?(String) && attributes[:logo].start_with?('http')
      # Don't update logo if it's just a URL string
      attributes = attributes.except(:logo)
    end
    
    # Only permit the basic scalar fields, complex nested data is handled separately
    attributes.permit(
      :name,
      :website,
      :email,
      :phone,
      :cost,
      :min_age,
      :max_age,
      :waitlist,
      :telehealth_services,
      :spanish_speakers,
      :at_home_services,
      :in_clinic_services,
      :status,
      :in_home_only,
      :category,  # Allow category for creation
      :logo,  # Only permit if it's a file upload
      service_delivery: {}
    )
  end
end