class ProviderController < ApplicationController
  def index
    providers = Providers.all
    render json: ProviderSerializer.format_providers(providers)
  end
end