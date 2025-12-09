class AuthController < ActionController::API
  # This controller doesn't inherit from ApplicationController, so no API key required

  def login
    begin
      Rails.logger.info "🔍 Login attempt - Raw params keys: #{params.keys.inspect}"
      Rails.logger.info "🔍 Login attempt - Content-Type: #{request.content_type}"
      
      # Rails API should auto-parse JSON into params
      # Try multiple ways to access user params
      user_params = params[:user] || params['user']
      
      Rails.logger.info "🔍 Login attempt - User params: #{user_params.inspect}"
      
      email = user_params&.dig(:email) || user_params&.dig('email') if user_params
      password = user_params&.dig(:password) || user_params&.dig('password') if user_params
      
      Rails.logger.info "🔍 Login attempt - Email: #{email.inspect}, Password present: #{password.present?}"
      
      unless email.present? && password.present?
        Rails.logger.warn "❌ Login failed - Missing email or password"
        render json: { error: 'Invalid email or password' }, status: :unauthorized
        return
      end
      
      # Normalize email (downcase and strip whitespace)
      email = email.to_s.downcase.strip
      
      user = User.find_by(email: email)
      
      Rails.logger.info "🔍 Login attempt - User found: #{user.present?}"
      Rails.logger.info "🔍 Login attempt - User ID: #{user.id if user}" if user
      
      if user
        # Check if user has an encrypted password set
        has_encrypted_password = user.encrypted_password.present?
        Rails.logger.info "🔍 Login attempt - User has encrypted_password: #{has_encrypted_password}"
        
        if !has_encrypted_password
          Rails.logger.error "❌ Login failed - User exists but has no encrypted_password set. User may need to reset password."
          render json: { error: 'Account setup incomplete. Please use password reset to set your password.' }, status: :unauthorized
          return
        end
        
        password_valid = user.valid_password?(password)
        Rails.logger.info "🔍 Login attempt - Password valid: #{password_valid}"
        
        # Additional debugging for password validation failures
        unless password_valid
          Rails.logger.warn "❌ Password validation failed for user #{user.id} (#{user.email})"
          Rails.logger.warn "❌ Encrypted password present: #{user.encrypted_password.present?}"
          Rails.logger.warn "❌ Encrypted password length: #{user.encrypted_password&.length || 0}"
        end
      end
      
      if user && user.valid_password?(password)
        # Convert string role to numeric for frontend compatibility
        numeric_role = case user.role.to_s
        when 'super_admin', '0'
          0
        when 'user', '1', 'provider', 'provider_admin'
          1
        else
          1
        end
        
        Rails.logger.info "✅ Login successful for user: #{user.id} (#{user.email})"
        
        render json: { 
          message: 'Login successful',
          user: {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            role: numeric_role,
            provider_id: user.provider_id
          }
        }, status: :ok
      else
        password_valid_status = user ? (user.valid_password?(password) rescue false) : 'N/A'
        Rails.logger.warn "❌ Login failed - User: #{user.present?}, Password valid: #{password_valid_status}"
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      end
    rescue => e
      Rails.logger.error "❌ Login error: #{e.class.name} - #{e.message}"
      Rails.logger.error "❌ Backtrace: #{e.backtrace.first(5).join('\n')}"
      render json: { error: 'An error occurred during login. Please try again.' }, status: :internal_server_error
    end
  end

  def signup
    user = User.new(user_params)
    
    if user.save
      # Convert string role to numeric for frontend compatibility
      numeric_role = case user.role
      when 'super_admin'
        0
      when 'user'
        1
      else
        1
      end
      
      render json: { 
        message: 'User created successfully',
        user: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          role: numeric_role,
          provider_id: user.provider_id
        }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def password_reset
    # Use the exact same email verification logic as the AuthenticationController login
    user = User.find_by(email: params[:email])
    
    if user
      begin
        user.send_reset_password_instructions
        render json: { message: 'Password reset instructions sent to your email' }, status: :ok
      rescue => e
        Rails.logger.error "Email sending failed: #{e.message}"
        render json: { error: 'Failed to send password reset email. Please try again later.' }, status: :internal_server_error
      end
    else
      # Use the same response logic as login - don't reveal if email exists or not
      render json: { error: 'If the email exists, password reset instructions have been sent' }, status: :ok
    end
  end

  def change_password
    # Get user from Bearer token (user ID)
    token = request.headers['Authorization']&.sub(/^Bearer\s+/,'')
    unless token
      render json: { error: 'No authorization token provided' }, status: :unauthorized
      return
    end
    
    user = User.find_by(id: token)
    unless user
      render json: { error: 'Invalid authorization token' }, status: :unauthorized
      return
    end
    
    # Verify current password
    unless user.valid_password?(params[:current_password])
      render json: { error: 'Current password is incorrect' }, status: :unauthorized
      return
    end
    
    # Update password
    if user.update(password: params[:new_password], password_confirmation: params[:new_password_confirmation])
      render json: { message: 'Password changed successfully' }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :provider_id, :role, :first_name)
  end
end 