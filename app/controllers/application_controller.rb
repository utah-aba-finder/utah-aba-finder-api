class ApplicationController < ActionController::API
  before_action :authenticate_client

  private

  def authenticate_client
    api_key = request.headers['Authorization']
    client = Client.find_by(api_key: api_key)

    unless client
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
