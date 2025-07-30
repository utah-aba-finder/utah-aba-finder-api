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
    if provider.update(provider_params)
      provider.update_locations(params[:data].first[:attributes][:locations])
      provider.update_provider_insurance(params[:data].first[:attributes][:insurance])
      # provider.update_counties(params[:data].first[:attributes][:counties_served])
      provider.update_counties_from_array(params[:data].first[:attributes][:counties_served].map { |county| county["county_id"] })
      provider.update_practice_types(params[:data].first[:attributes][:provider_type])
      provider.touch # Ensure updated_at is updated
      render json: ProviderSerializer.format_providers([provider])
    else
      render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
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
  def provider_params
    params.require(:data).first[:attributes].permit(
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