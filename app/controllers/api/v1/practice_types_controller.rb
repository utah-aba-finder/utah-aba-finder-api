class Api::V1::PracticeTypesController < ApplicationController
  skip_before_action :authenticate_client, only: [:index]
  
  def index
    practice_types = PracticeType.all.order(:name)
    
    render json: {
      data: practice_types.map do |practice_type|
        {
          id: practice_type.id,
          type: "practice_type",
          attributes: {
            name: practice_type.name,
            created_at: practice_type.created_at,
            updated_at: practice_type.updated_at
          }
        }
      end
    }
  end
end
