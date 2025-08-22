class Api::V1::States::ProvidersController < ApplicationController
  skip_before_action :authenticate_client
  
  def index
    state = State.find_by(id: params[:state_id])

    # First get unique provider IDs to avoid duplicates from county joins
    provider_ids = Provider
      .joins(counties: :state)
      .joins(:practice_types)
      .where(counties: { state_id: state.id })
      .where(status: "approved")
      .where(practice_types: { name: params[:provider_type] })
      .distinct
      .pluck(:id)

    # Then fetch the full provider records
    providers = Provider
      .includes(:counties, :practice_types, :locations, :insurances)
      .where(id: provider_ids)

    render json: ProviderSerializer.format_providers(providers)
  end
end