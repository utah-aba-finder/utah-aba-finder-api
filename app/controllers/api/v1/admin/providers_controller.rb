class Api::V1::Admin::ProvidersController < Api::V1::Admin::BaseController
  def index
    providers = Provider.all
    render json: {
      data: ProviderSerializer.format_providers(providers),
      meta: {
        waitlist_options: Location::WAITLIST_OPTIONS
      }
    }
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
    Rails.logger.info "🔍 Updating locations for provider #{provider.id}: #{locations_data.inspect}"
    
    # Clear existing locations
    provider.locations.destroy_all
    
    # Create new locations
    locations_data.each do |location_info|
      next unless location_info[:address_1].present? || location_info[:city].present?
      
      # Permit the location parameters so they can be accessed during validation
      permitted_location_info = location_info.permit(
        :name, :address_1, :address_2, :city, :state, :zip, :phone,
        :in_home_waitlist, :in_clinic_waitlist, services: [:id, :name]
      )
      
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
    
    # Clear existing services for this location
    location.practice_types.clear
    
    # Add new services
    services_data.each do |service_info|
      if service_info[:id].present?
        practice_type = PracticeType.find_by(id: service_info[:id])
        if practice_type
          location.practice_types << practice_type
          Rails.logger.info "✅ Added service #{practice_type.name} to location #{location.id}"
        else
          Rails.logger.warn "⚠️ Practice type not found by ID: #{service_info[:id]}"
        end
      elsif service_info[:name].present?
        practice_type = PracticeType.find_by(name: service_info[:name])
        if practice_type
          location.practice_types << practice_type
          Rails.logger.info "✅ Added service #{practice_type.name} to location #{location.id}"
        else
          Rails.logger.warn "⚠️ Practice type not found by name: #{service_info[:name]}"
        end
      end
    end
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
        :logo,  # Only permit if it's a file upload
        service_delivery: {}
      )
    end
  end
end