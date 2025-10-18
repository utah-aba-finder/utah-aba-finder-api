require 'securerandom'

class Api::V1::Admin::ProvidersController < Api::V1::Admin::BaseController
  include Pagy::Backend
  
  def index
    # Add pagination to prevent memory issues
    per_page = params[:per_page]&.to_i || 50
    per_page = [per_page, 100].min # Cap at 100 to prevent abuse
    
    providers_query = Provider.includes(:counties, :practice_types, :locations, :insurances)
                             .order(:name)
    
    @pagy, providers = pagy(providers_query, items: per_page)
    
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
    # Create provider with all necessary setup
    provider = Provider.new(admin_provider_params)
    
    # Set default status to approved for admin-created providers
    provider.status = :approved
    
    # Set default service delivery if not provided
    provider.service_delivery ||= { "in_home" => true, "in_clinic" => false }
    
    # Set default in_home_only to true to avoid location requirement initially
    provider.in_home_only = true if provider.in_home_only.nil?
    
    if provider.save
      # Create user account for the provider
      user = create_provider_user_account(provider)
      
      # Set up practice types if provided
      if params[:data]&.first&.dig(:attributes, :provider_type)&.present?
        provider.create_practice_types(params[:data].first[:attributes][:provider_type])
      end
      
      # Set up locations if provided
      if params[:data]&.first&.dig(:attributes, :locations)&.present?
        create_locations(provider, params[:data].first[:attributes][:locations])
      end
      
      # Set up counties served if provided
      if params[:data]&.first&.dig(:attributes, :counties_served)&.present?
        update_counties_served(provider, params[:data].first[:attributes][:counties_served])
      end
      
      # Set up insurance if provided
      if params[:data]&.first&.dig(:attributes, :insurance)&.present?
        setup_insurance(provider, params[:data].first[:attributes][:insurance])
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

    # Debug logging
    Rails.logger.info "🔍 Admin update - Provider ID: #{provider.id}"
    Rails.logger.info "🔍 Admin update - Basic Params: #{admin_provider_params.inspect}"
    Rails.logger.info "🔍 Admin update - Locations Params: #{locations_params.inspect}"
    Rails.logger.info "🔍 Admin update - Counties Params: #{counties_params.inspect}"
    Rails.logger.info "🔍 Admin update - States Params: #{states_params.inspect}"
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

      provider.touch # Ensure updated_at is updated
      render json: ProviderSerializer.format_providers([provider])
    else
      Rails.logger.error "❌ Admin update failed - Errors: #{provider.errors.full_messages}"
      render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def create_provider_user_account(provider)
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
      # Send welcome email with login credentials
      ProviderRegistrationMailer.admin_created_provider(provider, user).deliver_later
      Rails.logger.info "✅ Welcome email sent to #{provider.email}"
    rescue => e
      Rails.logger.error "❌ Failed to send welcome email: #{e.message}"
    end
  end

  def update_counties_served(provider, counties_data)
    Rails.logger.info "🔍 Updating counties for provider #{provider.id}: #{counties_data.inspect}"
    
    # Safer deletion with sanitization and no default_scope
    CountiesProvider.unscoped.where(provider_id: provider.id).delete_all
    
    # Recreate (also bypass default_scope to prevent the WHERE "" IS NULL filter)
    counties_data.each do |county_info|
      county_id = county_info[:county_id] || county_info["county_id"]
      if county_id.present?
        CountiesProvider.unscoped.create!(provider_id: provider.id, county_id: county_id)
        Rails.logger.info "✅ Added county #{county_id} for provider #{provider.id}"
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
      next unless location_info[:address_1].present? || location_info[:city].present?
      
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
      in_home_waitlist = permitted_location_info[:in_home_waitlist].present? ? permitted_location_info[:in_home_waitlist] : in_home_waitlist_default
      in_clinic_waitlist = permitted_location_info[:in_clinic_waitlist].present? ? permitted_location_info[:in_clinic_waitlist] : "Contact for availability"
      
      Rails.logger.info "🔍 DEBUG: Final in_home_waitlist: #{in_home_waitlist}"
      Rails.logger.info "🔍 DEBUG: Final in_clinic_waitlist: #{in_clinic_waitlist}"
      
      # Debug: Check exact string comparison
      Rails.logger.info "🔍 DEBUG: in_home_waitlist bytes: #{in_home_waitlist.bytes.inspect}"
      Rails.logger.info "🔍 DEBUG: in_home_waitlist length: #{in_home_waitlist.length}"
      Rails.logger.info "🔍 DEBUG: in_home_waitlist in WAITLIST_OPTIONS?: #{Location::WAITLIST_OPTIONS.include?(in_home_waitlist)}"
      Rails.logger.info "🔍 DEBUG: WAITLIST_OPTIONS: #{Location::WAITLIST_OPTIONS.inspect}"
      
      location = provider.locations.build(
        name: permitted_location_info[:name],
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

  def admin_provider_params
    # Handle both regular params and nested data format
    if params[:data].present?
      # Filter out logo if it's just a URL string (not a file upload)
      attributes = params.require(:data).first[:attributes]
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
    else
      # Handle direct params (for logo uploads)
      params.permit(
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
end