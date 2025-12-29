class Api::V1::ProviderSelfController < ApplicationController
  skip_before_action :authenticate_client, only: [:show, :update]
  before_action :authenticate_user!
  before_action :set_provider

  def show
    render json: ProviderSerializer.format_providers([@provider])
  end

  def update
    Rails.logger.info "Provider self-update - Content-Type: #{request.content_type}"
    Rails.logger.info "Provider self-update - Logo present: #{params[:logo].present?}"

    if request.content_type&.include?('multipart/form-data') || params[:logo].present?
      Rails.logger.info "Provider self-update - Using multipart path"
      # Handle multipart form data (for logo uploads)
      @provider.assign_attributes(multipart_provider_params)
      
      # Handle logo upload using Active Storage
      if params[:logo].present?
        Rails.logger.info "Provider self-update - Logo file received: #{params[:logo].original_filename}"
        @provider.logo.attach(params[:logo])
      end
      
      if @provider.save
        @provider.touch
        Rails.logger.info "Provider self-update - Saved successfully"
        render json: ProviderSerializer.format_providers([@provider])
      else
        Rails.logger.error "Provider self-update - Save failed: #{@provider.errors.full_messages}"
        render json: { errors: @provider.errors.full_messages }, status: :unprocessable_entity
      end
    else
      Rails.logger.info "Provider self-update - Using JSON path"
      Rails.logger.info "Provider self-update - provider_params: #{provider_params.inspect}"
      # Handle JSON data (for regular updates)
      if @provider.update(provider_params)
        Rails.logger.info "✅ Provider self-update - Basic provider fields updated successfully"
        
        # Extract attributes to check for locations and primary_location_id
        attributes = params[:data]&.first&.dig(:attributes) || {}
        primary_location_id = attributes[:primary_location_id] || attributes["primary_location_id"]
        locations_data = attributes[:locations] || attributes["locations"]
        
        # Convert primary_location_id to integer if present
        if primary_location_id.present?
          primary_location_id = primary_location_id.to_i if primary_location_id.to_i > 0
          Rails.logger.info "🔍 Provider self-update - primary_location_id from params: #{primary_location_id.inspect}"
        end
        
        # Update locations if locations data is provided
        if locations_data.present?
          Rails.logger.info "🔍 Provider self-update - Updating locations with primary_location_id: #{primary_location_id.inspect}"
          @provider.update_locations(locations_data, primary_location_id: primary_location_id)
        elsif primary_location_id.present?
          # If only primary_location_id is provided (without locations), update just the primary location
          Rails.logger.info "🔍 Provider self-update - Only primary_location_id provided, updating primary location to: #{primary_location_id.inspect}"
          if @provider.set_primary_location(primary_location_id)
            Rails.logger.info "✅ Provider self-update - Successfully set primary location to: #{primary_location_id}"
          else
            Rails.logger.warn "⚠️ Provider self-update - Failed to set primary location to: #{primary_location_id}"
          end
        end
        
        # Only update insurance if insurance data is provided
        if params[:data]&.first&.dig(:attributes, :insurance)&.present?
          @provider.update_provider_insurance(params[:data].first[:attributes][:insurance])
        end
        
        # Only update counties if counties data is provided
        if params[:data]&.first&.dig(:attributes, :counties_served)&.present?
          # Extract county IDs and filter out invalid ones (0, nil, etc.)
          county_ids = params[:data].first[:attributes][:counties_served].map { |county| county["county_id"] || county[:county_id] }.compact.reject { |id| id.to_i <= 0 }
          @provider.update_counties_from_array(county_ids)
        end
        
        # Only update practice types if practice type data is provided
        if params[:data]&.first&.dig(:attributes, :provider_type)&.present?
          @provider.update_practice_types(params[:data].first[:attributes][:provider_type])
        end
        
        # Handle provider_attributes (category-specific fields)
        if params[:data]&.first&.dig(:attributes, :provider_attributes)&.present?
          update_provider_attributes(params[:data].first[:attributes][:provider_attributes])
        end
        
        @provider.touch
        # Reload provider with associations to ensure fresh data (especially locations and primary_location_id)
        @provider.reload
        @provider = Provider.includes(
          :practice_types,
          { :locations => :practice_types },
          { :provider_insurances => :insurance },
          { :provider_attributes => :category_field },
          { :provider_category => :category_fields },
          :counties
        ).find(@provider.id)
        render json: ProviderSerializer.format_providers([@provider])
      else
        render json: { errors: @provider.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def remove_logo
    @provider.logo.purge if @provider.logo.attached?
    render json: { message: 'Logo removed successfully' }
  end

  private

  def set_provider
    # Try active_provider first, fall back to user.provider if not set
    @provider = @current_user.active_provider || @current_user.provider
    
    unless @provider
      render json: { error: 'No provider found. Please set an active provider or link a provider to your account.' }, status: :not_found
      return
    end
    
    # Verify user has access to this provider
    unless @current_user.can_access_provider?(@provider.id)
      render json: { error: 'Access denied. You do not have permission to access this provider.' }, status: :forbidden
      return
    end
  end

  def multipart_provider_params
    params.permit(
      :name, :website, :email, :cost, :min_age, :max_age, :waitlist,
      :telehealth_services, :spanish_speakers, :at_home_services, 
      :in_clinic_services, :in_home_only, :service_delivery, :phone
    )
  end

  def provider_params
    if params[:data]&.first&.dig(:attributes)
      params.require(:data).first.require(:attributes).permit(
        :name, :website, :email, :cost, :min_age, :max_age, :waitlist,
        :telehealth_services, :spanish_speakers, :at_home_services, 
        :in_clinic_services, :in_home_only, :service_delivery, :phone
      )
    else
      params.permit(
        :name, :website, :email, :cost, :min_age, :max_age, :waitlist,
        :telehealth_services, :spanish_speakers, :at_home_services, 
        :in_clinic_services, :in_home_only, :service_delivery, :phone
      )
    end
  end

  def update_provider_attributes(attributes_data)
    # attributes_data should be a hash like: { "field_name" => "value", "another_field" => "value" }
    # Handle ActionController::Parameters by converting to hash
    if attributes_data.is_a?(ActionController::Parameters)
      attributes_data = attributes_data.to_unsafe_h
    end
    return unless attributes_data.is_a?(Hash)

    Rails.logger.info "🔍 Provider self - Updating provider_attributes for provider #{@provider.id}: #{attributes_data.inspect}"

    attributes_data.each do |field_name, value|
      # Find the category field by name (case-insensitive)
      field = @provider.category_fields.find_by('LOWER(name) = LOWER(?)', field_name)
      unless field
        Rails.logger.warn "⚠️ Provider self - Category field '#{field_name}' not found for provider #{@provider.id} (category: #{@provider.category})"
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
      if @provider.set_attribute_value(field_name, processed_value)
        Rails.logger.info "✅ Provider self - Updated attribute '#{field_name}' for provider #{@provider.id}: #{processed_value}"
      else
        Rails.logger.error "❌ Provider self - Failed to update attribute '#{field_name}' for provider #{@provider.id}"
      end
    end
  end
end 