class Api::V1::StatesController < ApplicationController
  def index
    @states = State.all
    render json: StateSerializer.format_states(@states)
  end
end
