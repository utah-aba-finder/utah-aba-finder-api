class Api::V1::ProvidersController < ApplicationController
  def index
    providers = Provider.all
    render json: ProviderSerializer.format_providers(providers)
  end

  def create
    provider = Provider.new(provider_params)
    if provider.save
      # binding.pry
      params[:locations].each do |location|
        provider.locations.create!(
          name: location[:name],
          address_1: location[:address_1] ,
          address_2: location[:address_s] ,
          city: location[:city] ,
          state: location[:state] ,
          zip: location[:zip] ,
          phone: location[:phone] 
          )
        end
        binding.pry
      provider.counties_served.create!(counties_served_params)
      provider.insurances.each do |insurance|
        ProviderInsurances.create!(provider, insurance)
      end
      render
    end
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
      :in_clinic_services
      # :npi
      )
  end
end