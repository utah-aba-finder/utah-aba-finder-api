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
    
    # Debug logging
    Rails.logger.info "🔍 Admin update - Provider ID: #{provider.id}"
    Rails.logger.info "🔍 Admin update - Params: #{admin_provider_params.inspect}"
    Rails.logger.info "🔍 Admin update - Current category: #{provider.category}"
    
    if provider.update(admin_provider_params)
      # Update practice types if provided
      if practice_type_params.present?
        provider.update_practice_types(practice_type_params)
      end
      
      # Update locations if provided
      if locations_params.present?
        update_locations(provider, locations_params)
      end
      
      # Update counties served if provided
      if params[:data]&.first&.dig(:attributes, :counties_served)&.present?
        update_counties_served(provider, params[:data].first[:attributes][:counties_served])
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
      
      location = provider.locations.build(
        name: location_info[:name],
        address_1: location_info[:address_1],
        address_2: location_info[:address_2],
        city: location_info[:city],
        state: location_info[:state],
        zip: location_info[:zip],
        phone: location_info[:phone],
        in_home_waitlist: location_info[:in_home_waitlist] || "Contact for availability",
        in_clinic_waitlist: location_info[:in_clinic_waitlist] || "Contact for availability"
      )
      
      if location.save
        Rails.logger.info "✅ Added location #{location.id} for provider #{provider.id}"
        
        # Handle services for this location if provided
        if location_info[:services].present?
          update_location_services(location, location_info[:services])
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
      ) # Removed .except(:counties_served, :states) to allow these fields to be processed
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
      ) # Removed .except(:counties_served, :states) to allow these fields to be processed
    end
  end
end