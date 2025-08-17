class ApplicationController < ActionController::API
  before_action :authenticate_client, unless: :skip_client_auth?

  attr_reader :current_user, :current_client  # so current_user/current_client calls work

  private

  # Only run API-key auth when we really want it.
  def skip_client_auth?
    return true if devise_controller?
    return true if admin_controller?
    auth = request.headers['Authorization'].to_s
    # If it's a Bearer token, let downstream user/provider auth handle it
    return true if auth.start_with?('Bearer ')
    false
  end

  # Define this if you actually have admin controllers; otherwise just return false
  def admin_controller?
    controller_path.start_with?('api/v1/admin/')
  end

  def devise_controller?
    # Skip authentication for Devise controllers
    controller_name.start_with?('sessions', 'registrations', 'passwords', 'password_resets', 'confirmations', 'unlocks')
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
    user = User.find_by(id: token)
    unless user
      render json: { error: 'Invalid authorization token' }, status: :unauthorized and return
    end
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
      if (user = User.find_by(id: token))
        @current_user = user
        provider_id = params[:id].to_s

        # Super admin can edit any provider
        if current_user.role == 'super_admin' || current_user.role.to_s == '0'
          Rails.logger.info "Provider auth - Super admin access granted"
          return
        end

        # Primary owner
        if current_user.provider_id.to_s == provider_id
          Rails.logger.info "Provider auth - User provider access granted"
          return
        end

        # Assigned/managed providers
        if current_user.all_managed_providers.where(id: provider_id).exists?
          Rails.logger.info "Provider auth - User managed provider access granted"
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
