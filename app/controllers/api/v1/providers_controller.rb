class Api::V1::ProvidersController < ApplicationController
  def index
    providers = Provider.all
    render json: ProviderSerializer.format_providers(providers)
  end

  # def create
  #   provider = Provider.new(provider_params)
  #   if provider.save
  #     # should create method in provider model to handle extra creation/association logic
  #     params[:locations].each do |location|
  #       provider.locations.create!(
  #         name: location[:name],
  #         address_1: location[:address_1] ,
  #         address_2: location[:address_2] ,
  #         city: location[:city] ,
  #         state: location[:state] ,
  #         zip: location[:zip] ,
  #         phone: location[:phone] 
  #         )
  #       end
  #     provider.counties.create!(counties_served: params[:counties_served])
  #     params[:insurance].each do |insurance|
  #       insurance_found = Insurance.find_by(name: insurance[:name])
  #       ProviderInsurance.create!(provider_id: provider.id, insurance_id: insurance_found.id)
  #     end
  #     render json: ProviderSerializer.format_providers([provider])
  #   end
  # end

  def update
    provider = Provider.find(params[:id])
    provider.update!(provider_params)
    render json: ProviderSerializer.format_providers([provider])
  end

  def show
    provider = Provider.find(params[:id])
    render json: ProviderSerializer.format_providers([provider])
  end

  private
  def provider_params
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
      :logo
      # :npi
      )
  end
end