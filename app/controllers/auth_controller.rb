class AuthController < ActionController::API
  # This controller doesn't inherit from ApplicationController, so no API key required

  def login
    user = User.find_by(email: params[:user][:email])
    
    if user && user.valid_password?(params[:user][:password])
      # Convert string role to numeric for frontend compatibility
      numeric_role = case user.role
      when 'super_admin'
        1
      when 'user'
        0
      else
        0
      end
      
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
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def signup
    user = User.new(user_params)
    
    if user.save
      # Convert string role to numeric for frontend compatibility
      numeric_role = case user.role
      when 'super_admin'
        1
      when 'user'
        0
      else
        0
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

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :provider_id, :role)
  end
end 