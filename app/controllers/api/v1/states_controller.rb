class Api::V1::StatesController < ApplicationController
  skip_before_action :authenticate_client, only: [:index]
  
  def index
    @states = State.all
    render json: StateSerializer.format_states(@states)
  end
end
