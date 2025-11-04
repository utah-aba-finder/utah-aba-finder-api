class AuthController < ActionController::API
  # This controller doesn't inherit from ApplicationController, so no API key required

  def login
    Rails.logger.info "🔍 Login attempt - Params: #{params.inspect}"
    Rails.logger.info "🔍 Login attempt - User params: #{params[:user].inspect}"
    
    email = params[:user]&.dig(:email)
    password = params[:user]&.dig(:password)
    
    Rails.logger.info "🔍 Login attempt - Email: #{email.inspect}, Password present: #{password.present?}"
    
    user = User.find_by(email: email) if email.present?
    
    Rails.logger.info "🔍 Login attempt - User found: #{user.present?}"
    Rails.logger.info "🔍 Login attempt - User ID: #{user.id if user}"
    
    if user && password.present?
      password_valid = user.valid_password?(password)
      Rails.logger.info "🔍 Login attempt - Password valid: #{password_valid}"
    end
    
    if user && password.present? && user.valid_password?(password)
      # Convert string role to numeric for frontend compatibility
      numeric_role = case user.role
      when 'super_admin'
        0
      when 'user'
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
          role: numeric_role,
          provider_id: user.provider_id
        }
      }, status: :ok
    else
      Rails.logger.warn "❌ Login failed - User: #{user.present?}, Password valid: #{user ? user.valid_password?(password) : 'N/A'}"
      render json: { error: 'Invalid email or password' }, status: :unauthorized
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
    # Require authentication for password changes
    authenticate_user!
    
    user = current_user
    
    if user.valid_password?(params[:current_password])
      if user.update(password: params[:new_password], password_confirmation: params[:new_password_confirmation])
        render json: { message: 'Password changed successfully' }
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Current password is incorrect' }, status: :unauthorized
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :provider_id, :role)
  end
end 