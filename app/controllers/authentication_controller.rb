class AuthenticationController < ActionController::API
  # No need to skip authenticate_client since this controller doesn't inherit from ApplicationController

  def login
    user = User.find_by(email: params[:user][:email])
    
    if user && user.valid_password?(params[:user][:password])
      render json: { 
        message: 'Login successful',
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id
        }
      }, status: :ok
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def signup
    user = User.new(user_params)
    # Set default role to 1 (regular provider) unless explicitly set to 0 (super admin)
    user.role = 1 unless user.role == 0
    
    if user.save
      render json: { 
        message: 'User created successfully',
        user: {
          id: user.id,
          email: user.email,
          provider_id: user.provider_id,
          role: user.role
        }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :provider_id)
  end
end 