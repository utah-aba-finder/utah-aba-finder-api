class ApplicationController < ActionController::API
  before_action :authenticate_client, unless: :devise_controller?

  private

  def authenticate_client
    api_key = request.headers['Authorization']
    Rails.logger.info "API key received: #{api_key}"
    Rails.logger.info "All headers: #{request.headers.to_h}"
    
    client = Client.find_by(api_key: api_key)
    Rails.logger.info "Client found: #{client.present?}"
    
    unless client
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def devise_controller?
    # Skip authentication for Devise controllers
    controller_name.start_with?('sessions', 'registrations', 'passwords', 'password_resets', 'confirmations', 'unlocks')
  end
end
