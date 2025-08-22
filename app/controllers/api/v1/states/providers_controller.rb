class Api::V1::States::ProvidersController < ApplicationController
  skip_before_action :authenticate_client
  
  def index
    state = State.find_by(id: params[:state_id])

    providers = Provider
    .joins(counties: :state)
    .joins(:practice_types)
    .where(counties: { state_id: state.id })
    .where(status: "approved")
    .where(practice_types: { name: params[:provider_type] })
    .distinct

    render json: ProviderSerializer.format_providers(providers)
  end
end