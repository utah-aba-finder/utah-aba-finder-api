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
      # Handle JSON data (for regular updates)
      if @provider.update(provider_params)
        # Only update locations if locations data is provided
        if params[:data]&.first&.dig(:attributes, :locations)&.present?
          @provider.update_locations(params[:data].first[:attributes][:locations])
        end
        
        # Only update insurance if insurance data is provided
        if params[:data]&.first&.dig(:attributes, :insurance)&.present?
          @provider.update_provider_insurance(params[:data].first[:attributes][:insurance])
        end
        
        # Only update counties if counties data is provided
        if params[:data]&.first&.dig(:attributes, :counties_served)&.present?
          @provider.update_counties_from_array(params[:data].first[:attributes][:counties_served].map { |county| county["county_id"] })
        end
        
        # Only update practice types if practice type data is provided
        if params[:data]&.first&.dig(:attributes, :provider_type)&.present?
          @provider.update_practice_types(params[:data].first[:attributes][:provider_type])
        end
        
        @provider.touch
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
    @provider = current_user.provider
    unless @provider
      render json: { error: 'No provider associated with this user' }, status: :not_found
    end
  end

  def multipart_provider_params
    params.permit(
      :name, :description, :website, :phone, :email, :in_home_only, :service_delivery
    )
  end

  def provider_params
    if params[:data]&.first&.dig(:attributes)
      params.require(:data).first.require(:attributes).permit(
        :name, :description, :website, :phone, :email, :in_home_only, :service_delivery
      )
    else
      params.permit(:name, :description, :website, :phone, :email, :in_home_only, :service_delivery)
    end
  end
end 