class Api::V1::ProvidersController < ApplicationController
  def index
    if params[:provider_type].present?
      providers = Provider.where(status: :approved, provider_type: params[:provider_type])
    else
      providers = Provider.where(status: :approved)
    end
    render json: ProviderSerializer.format_providers(providers)
  end

  def create
    provider = Provider.new(provider_params)
    if provider.save
      provider.initialize_provider_insurances
      # should create methods in provider model to handle extra creation/association logic
      params[:data].first[:attributes][:locations].each do |location|
        provider.locations.create!(
          name: location[:name],
          address_1: location[:address_1] ,
          address_2: location[:address_2] ,
          city: location[:city] ,
          state: location[:state] ,
          zip: location[:zip] ,
          phone: location[:phone] 
        )
      end
      # provider.old_counties.create!(counties_served: params[:data].first[:attributes][:counties_served])
      # Update counties (new logic)
      provider.update_counties_from_array(params[:data].first[:attributes][:counties_served].map { |county| county["county_id"] })

      params[:data].first[:attributes][:insurance].each do |insurance|
        insurance_found = Insurance.find(insurance[:id])
        provider_insurance = ProviderInsurance.find_by(provider_id: provider.id, insurance_id: insurance_found.id)
        provider_insurance.update!(accepted: true) if provider_insurance
      end

      provider.create_practice_types(params[:data].first[:attributes][:provider_type])

      render json: ProviderSerializer.format_providers([provider])
    else
      render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    provider = Provider.find(params[:id])

    Rails.logger.info "Content-Type: #{request.content_type}"
    Rails.logger.info "Logo present: #{params[:logo].present?}"
    Rails.logger.info "Multipart condition: #{request.content_type&.include?('multipart/form-data') || params[:logo].present?}"

    if request.content_type&.include?('multipart/form-data') || params[:logo].present?
      Rails.logger.info "Using multipart path"
      # Handle multipart form data (for logo uploads)
      provider.assign_attributes(multipart_provider_params)
      
          # Handle logo upload using Active Storage
    if params[:logo].present?
      Rails.logger.info "Logo file received: #{params[:logo].original_filename}"
      Rails.logger.info "Params logo content type: #{params[:logo].content_type}"
      Rails.logger.info "Params logo original filename: #{params[:logo].original_filename}"
      Rails.logger.info "Params logo content length: #{params[:logo].size}"
      Rails.logger.info "Active Storage attached before?: #{provider.logo.attached?}"
      
      # Attach the logo file to Active Storage
      provider.logo.attach(params[:logo])
      
      Rails.logger.info "Active Storage attached after?: #{provider.logo.attached?}"
    end
      
      # Ensure required fields are preserved if not provided
      provider.in_home_only = provider.in_home_only unless params[:in_home_only].present?
      provider.service_delivery = provider.service_delivery unless params[:service_delivery].present?
      
      if provider.save
        provider.touch
        Rails.logger.info "Provider saved successfully. Logo URL: #{provider.logo_url}"
        render json: ProviderSerializer.format_providers([provider])
      else
        Rails.logger.error "Provider save failed: #{provider.errors.full_messages}"
        render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
      end
    else
      Rails.logger.info "Using JSON path"
      # Handle JSON data (for regular updates)
      if provider.update(provider_params)
        # Only update locations if locations data is provided
        if params[:data]&.first&.dig(:attributes, :locations)&.present?
          provider.update_locations(params[:data].first[:attributes][:locations])
        end
        
        # Only update insurance if insurance data is provided
        if params[:data]&.first&.dig(:attributes, :insurance)&.present?
          provider.update_provider_insurance(params[:data].first[:attributes][:insurance])
        end
        
        # Only update counties if counties data is provided
        if params[:data]&.first&.dig(:attributes, :counties_served)&.present?
          provider.update_counties_from_array(params[:data].first[:attributes][:counties_served].map { |county| county["county_id"] })
        end
        
        # Only update practice types if practice type data is provided
        if params[:data]&.first&.dig(:attributes, :provider_type)&.present?
          provider.update_practice_types(params[:data].first[:attributes][:provider_type])
        end
        
        provider.touch # Ensure updated_at is updated
        render json: ProviderSerializer.format_providers([provider])
      else
        render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def remove_logo
    provider = Provider.find(params[:id])
    provider.remove_logo
    provider.touch # Update the timestamp
    render json: { message: 'Logo removed successfully' }
  end

  def show
    provider = Provider.find(params[:id])
    render json: ProviderSerializer.format_providers([provider])
  end

  private
  
  def multipart_provider_params
    params.permit(
      :name,
      :website,
      :email,
      :cost,
      :min_age,
      :max_age,
      :waitlist,
      :telehealth_services,
      :spanish_speakers,
      :at_home_services,
      :in_clinic_services,
      :status,
      :provider_type,
      :in_home_only,
      :logo,
      service_delivery: {}
    )
  end

  def provider_params
    if params[:data]&.first&.dig(:attributes)
      params[:data].first[:attributes].permit(
        :name,
        :website,
        :email,
        :cost,
        :min_age,
        :max_age,
        :waitlist,
        :telehealth_services,
        :spanish_speakers,
        :at_home_services,
        :in_clinic_services,
        :status,
        :provider_type,
        :in_home_only,
        logo: [],
        service_delivery: {}
      )
    else
      # Fallback for simple updates
      params.permit(
        :name,
        :website,
        :email,
        :cost,
        :min_age,
        :max_age,
        :waitlist,
        :telehealth_services,
        :spanish_speakers,
        :at_home_services,
        :in_clinic_services,
        :status,
        :provider_type,
        :in_home_only,
        logo: [],
        service_delivery: {}
      )
    end
  end
end