class Api::V1::CountiesController < ApplicationController
  def index
    @state = State.find(params[:state_id])
    @counties = @state.counties
    render json: CountySerializer.format_counties(@counties)
  end
end
