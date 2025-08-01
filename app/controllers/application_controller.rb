class ApplicationController < ActionController::API
  before_action :authenticate_client, unless: :devise_controller?

  private

  def authenticate_client
    api_key = request.headers['Authorization']
    client = Client.find_by(api_key: api_key)

    unless client
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def devise_controller?
    # Skip authentication for Devise controllers
    controller_name.start_with?('sessions', 'registrations', 'passwords', 'password_resets', 'confirmations', 'unlocks')
  end
end
