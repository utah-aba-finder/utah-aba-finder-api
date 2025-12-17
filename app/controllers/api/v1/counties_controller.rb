class Api::V1::CountiesController < ApplicationController
  skip_before_action :authenticate_client, only: [:index]
  
  def index
    @state = State.find_by(id: params[:state_id])
    
    unless @state
      render json: { error: 'State not found' }, status: :not_found
      return
    end
    
    @counties = @state.counties.includes(:state).order(:name)
    render json: CountySerializer.format_counties(@counties)
  end
end
