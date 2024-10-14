class Api::V1::Admin::ProvidersController < ApplicationController
  def index
    providers = Provider.all
    render json: ProviderSerializer.format_providers(providers)
  end
end