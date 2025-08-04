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

  def authenticate_user!
    # Get the token from the Authorization header
    token = request.headers['Authorization']&.gsub('Bearer ', '')
    
    unless token
      render json: { error: 'No authorization token provided' }, status: :unauthorized
      return
    end

    # Find user by token (you might want to implement a proper JWT or session-based auth)
    # For now, let's use a simple approach - you can enhance this later
    user = User.find_by(id: token)
    
    unless user
      render json: { error: 'Invalid authorization token' }, status: :unauthorized
      return
    end

    @current_user = user
  end

  def current_user
    @current_user
  end

  def authenticate_provider_or_client
    # First try to authenticate as a user (provider self-editing)
    token = request.headers['Authorization']&.gsub('Bearer ', '')
    
    Rails.logger.info "Provider auth - Token: #{token}"
    Rails.logger.info "Provider auth - Params ID: #{params[:id]}"
    
    if token.present?
      # Try user authentication first
      user = User.find_by(id: token)
      Rails.logger.info "Provider auth - User found: #{user.present?}"
      
      if user
        @current_user = user
        provider_id = params[:id]
        
        # Super admin can edit any provider
        if current_user.role == 'super_admin' || current_user.role == 0
          Rails.logger.info "Provider auth - Super admin access granted"
          return
        end
        
        # Regular users can only edit their own provider
        if current_user.provider_id.to_s == provider_id.to_s
          Rails.logger.info "Provider auth - User provider access granted"
          return
        else
          Rails.logger.info "Provider auth - User provider access denied, trying provider ID auth"
          # If user auth fails, try provider ID authentication instead
          # Don't return error yet, let it fall through to provider ID check
        end
      end
      
      # If no user found, try provider ID authentication (frontend sends provider ID directly)
      provider = Provider.find_by(id: token)
      Rails.logger.info "Provider auth - Provider found: #{provider.present?}"
      
      if provider
        provider_id = params[:id]
        
        # Provider can only edit themselves
        if provider.id.to_s == provider_id.to_s
          Rails.logger.info "Provider auth - Provider self access granted"
          return
        else
          Rails.logger.info "Provider auth - Provider self access denied"
          render json: { error: 'Unauthorized - can only edit your own provider' }, status: :unauthorized
          return
        end
      end
    end
    
    # If user/provider authentication failed, try API key authentication
    api_key = request.headers['Authorization']
    client = Client.find_by(api_key: api_key)
    Rails.logger.info "Provider auth - Client found: #{client.present?}"
    
    if client
      @current_client = client
      Rails.logger.info "Provider auth - API key authentication successful"
      return
    end
    
    Rails.logger.info "Provider auth - All authentication methods failed"
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
