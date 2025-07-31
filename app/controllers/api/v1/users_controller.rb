class Api::V1::UsersController < ApplicationController
  skip_before_action :authenticate_client, only: [:index, :show, :create]

  # GET /api/v1/users
  # List all users (for Super Admin)
  def index
    users = User.all
    render json: {
      users: users.map { |user| { id: user.id, email: user.email, created_at: user.created_at } }
    }, status: :ok
  end

  # GET /api/v1/users/:id
  # Get specific user details
  def show
    user = User.find_by(id: params[:id])
    
    if user
      render json: {
        user: {
          id: user.id,
          email: user.email,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      }, status: :ok
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  # POST /api/v1/users
  # Create a new user (for Super Admin)
  def create
    user = User.new(user_params)
    
    if user.save
      render json: {
        message: 'User created successfully',
        user: {
          id: user.id,
          email: user.email,
          created_at: user.created_at
        }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end 