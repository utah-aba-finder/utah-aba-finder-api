class Api::V1::Admin::ProvidersController < Api::V1::Admin::BaseController
  def index
    providers = Provider.all
    render json: ProviderSerializer.format_providers(providers)
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
    
    # Debug logging
    Rails.logger.info "🔍 Admin update - Provider ID: #{provider.id}"
    Rails.logger.info "🔍 Admin update - Params: #{admin_provider_params.inspect}"
    Rails.logger.info "🔍 Admin update - Current category: #{provider.category}"
    
    if provider.update(admin_provider_params)
      # Update practice types if provided
      if practice_type_params.present?
        provider.update_practice_types(practice_type_params)
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
    
    # Clear existing county associations using the join table directly
    CountiesProvider.where(provider_id: provider.id).destroy_all
    
    # Add new county associations
    counties_data.each do |county_info|
      county_id = county_info[:county_id] || county_info["county_id"]
      if county_id.present?
        CountiesProvider.create!(provider_id: provider.id, county_id: county_id)
        Rails.logger.info "✅ Added county #{county_id} for provider #{provider.id}"
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