class ApplicationController < ActionController::API
  before_action :authenticate_client, unless: :skip_client_auth?
  after_action :set_cors_headers
  rescue_from StandardError, with: :handle_error

  attr_reader :current_user, :current_client  # so current_user/current_client calls work

  private

  # Only run API-key auth when we really want it.
  def skip_client_auth?
    return true if devise_controller?
    return true if admin_controller?
    return true if health_check_controller?
    auth = request.headers['Authorization'].to_s
    # If it's a Bearer token, let downstream user/provider auth handle it
    return true if auth.start_with?('Bearer ')
    false
  end
  
  def health_check_controller?
    controller_name == 'health' || controller_name == 'rails/health'
  end
  
  def handle_error(exception)
    # Log the error
    Rails.logger.error "❌ Error: #{exception.class.name} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    # Don't expose internal errors in production
    if Rails.env.production?
      render json: { 
        error: "An internal error occurred",
        request_id: request.uuid
      }, status: :internal_server_error
    else
      render json: { 
        error: exception.message,
        class: exception.class.name,
        backtrace: exception.backtrace.first(10),
        request_id: request.uuid
      }, status: :internal_server_error
    end
  end

  # Define this if you actually have admin controllers; otherwise just return false
  def admin_controller?
    controller_path.start_with?('api/v1/admin/')
  end

  def devise_controller?
    # Skip authentication for Devise controllers
    controller_name.start_with?('sessions', 'registrations', 'passwords', 'password_resets', 'confirmations', 'unlocks')
  end

  def set_cors_headers
    # Ensure CORS headers are set on all responses, including errors
    # Rack::Cors should handle this, but we ensure it as a fallback
    origin = request.headers['Origin']
    if origin && allowed_origin?(origin)
      headers['Access-Control-Allow-Origin'] = origin
      headers['Access-Control-Allow-Credentials'] = 'true'
    end
  end

  def allowed_origin?(origin)
    allowed_origins = [
      'http://localhost:3000',
      'https://autismserviceslocator.com',
      'https://www.autismserviceslocator.com'
    ]
    frontend_url = ENV['FRONTEND_URL'].presence
    allowed_origins << frontend_url if frontend_url
    allowed_origins.include?(origin)
  end

  def authenticate_client
    api_key = request.headers['Authorization'].to_s

    # Never try to treat a Bearer token as an API key
    return if api_key.start_with?('Bearer ')

    Rails.logger.info "API key received: #{api_key.inspect}"
    client = Client.find_by(api_key: api_key)
    Rails.logger.info "Client found: #{client.present?}"

    unless client
      render json: { error: 'Unauthorized' }, status: :unauthorized and return
    end
    @current_client = client
  end

  def authenticate_user!
    token = request.headers['Authorization']&.sub(/^Bearer\s+/,'')
    unless token
      render json: { error: 'No authorization token provided' }, status: :unauthorized and return
    end
    
    Rails.logger.info "🔍 Auth - Token received: #{token.inspect}"
    Rails.logger.info "🔍 Auth - Token length: #{token.length}"
    Rails.logger.info "🔍 Auth - Token looks like ID: #{token.match?(/^\d+$/)}"
    Rails.logger.info "🔍 Auth - Token looks like email: #{token.include?('@')}"
    
    # Try to find user by ID first (for simple token auth)
    user = User.find_by(id: token)
    Rails.logger.info "🔍 Auth - User found by ID: #{user.present?}"
    
    # If not found by ID, try to handle other token formats
    unless user
      begin
        # Try to decode as JWT or handle other token formats
        # For now, let's try to find by email if it looks like an email
        # Normalize email (downcase) for matching
        if token.include?('@')
          normalized_email = token.downcase.strip
          user = User.find_by('LOWER(email) = ?', normalized_email)
          Rails.logger.info "🔍 Auth - User found by email: #{user.present?} (searched for: #{normalized_email})"
        end
        
        # If still not found, try to handle session tokens or other formats
        unless user
          Rails.logger.warn "❌ Auth - Token not found as user ID or email: #{token}"
          # For now, let's try to handle this more gracefully
          # You might want to implement proper JWT decoding here
          render json: { error: 'Invalid authorization token' }, status: :unauthorized and return
        end
      rescue => e
        Rails.logger.error "❌ Auth - Token authentication error: #{e.message}"
        render json: { error: 'Invalid authorization token' }, status: :unauthorized and return
      end
    end
    
    Rails.logger.info "✅ Auth - Authentication successful for user: #{user.id} (#{user.email})"
    @current_user = user
  end

  def authenticate_provider_or_client
    auth = request.headers['Authorization'].to_s
    bearer = auth.start_with?('Bearer ')
    token  = bearer ? auth.sub(/^Bearer\s+/,'') : nil

    Rails.logger.info "Provider auth - Raw Authorization: #{auth.inspect}"
    Rails.logger.info "Provider auth - Token: #{token.inspect}"
    Rails.logger.info "Provider auth - Params ID: #{params[:id]}"

    # 1) Bearer user (preferred path)
    if bearer && token.present?
      # Try to find user by ID first
      user = User.find_by(id: token)
      
      # If not found by ID, try email lookup (normalized)
      unless user
        if token.include?('@')
          normalized_email = token.downcase.strip
          user = User.find_by('LOWER(email) = ?', normalized_email)
          Rails.logger.info "Provider auth - User found by email: #{user.present?} (searched for: #{normalized_email})"
        end
      end
      
      if user
        @current_user = user
        provider_id = params[:id].to_s

        # Super admin can edit any provider
        if current_user.role == 'super_admin' || current_user.role.to_s == '0'
          Rails.logger.info "Provider auth - Super admin access granted"
          return
        end

        # Legacy provider_id relationship OR primary owner OR assigned/managed providers
        # All are treated equally - any assigned user can edit
        if current_user.provider_id.to_s == provider_id || 
           current_user.all_managed_providers.where(id: provider_id).exists?
          Rails.logger.info "Provider auth - User provider access granted"
          return
        end

        Rails.logger.info "Provider auth - User provider access denied"
        render json: { error: 'Access denied - You do not have permission to access this provider' }, status: :forbidden and return
      end

      # If header is Bearer but doesn't match a user, DO NOT fall back to API-key here.
      render json: { error: 'Invalid authorization token' }, status: :unauthorized and return
    end

    # 2) Provider self (rare, only if you explicitly send provider id as token)
    if bearer && (provider = Provider.find_by(id: token))
      if provider.id.to_s == params[:id].to_s
        Rails.logger.info "Provider auth - Provider self access granted"
        return
      else
        Rails.logger.info "Provider auth - Provider self access denied"
        render json: { error: 'Unauthorized - can only edit your own provider' }, status: :unauthorized and return
      end
    end

    # 3) API key
    client = Client.find_by(api_key: auth)
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
