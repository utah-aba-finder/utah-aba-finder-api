class Api::V1::StatesController < ApplicationController
  def index
    @states = State.order(:name)
    render json: StateSerializer.format_states(@states)
  end
end
