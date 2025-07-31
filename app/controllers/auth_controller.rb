class AuthController < ActionController::API
  # This controller doesn't inherit from ApplicationController, so no API key required

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
    
    if user.save
      render json: { 
        message: 'User created successfully',
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id
        }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :provider_id, :role)
  end
end 