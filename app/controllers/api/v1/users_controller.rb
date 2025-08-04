class Api::V1::UsersController < ApplicationController
  skip_before_action :authenticate_client, only: [:index, :show, :create, :check_user_exists, :debug_lookup]

  # GET /api/v1/users
  # List all users (for Super Admin)
  def index
    users = User.all
    render json: {
      users: users.map { |user| 
        { 
          id: user.id, 
          email: user.email, 
          role: user.role,
          provider_id: user.provider_id,
          created_at: user.created_at 
        } 
      }
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

  # POST /api/v1/users/check_user_exists
  # Check if a user exists by email (for password reset verification)
  def check_user_exists
    email = params[:email]
    
    if email.blank?
      render json: { error: 'Email is required' }, status: :bad_request
      return
    end

    # Use the same user lookup logic as the login system
    user = User.find_by(email: email)
    
    if user
      render json: { 
        exists: true,
        message: 'User found',
        user: {
          id: user.id,
          email: user.email,
          created_at: user.created_at
        }
      }, status: :ok
    else
      render json: { 
        exists: false,
        message: 'User not found',
        email: email
      }, status: :not_found
    end
  end

  # GET /api/v1/users/debug_lookup
  # Debug endpoint to check where users might be stored
  def debug_lookup
    email = params[:email]
    
    if email.blank?
      render json: { error: 'Email is required' }, status: :bad_request
      return
    end

    results = {
      email: email,
      checks: {}
    }

    # Check users table
    user = User.find_by(email: email)
    results[:checks][:users_table] = user ? { found: true, id: user.id } : { found: false }

    # Check clients table
    client = Client.find_by(email: email)
    results[:checks][:clients_table] = client ? { found: true, id: client.id } : { found: false }

    # Check if any table has this email
    any_found = user || client
    results[:any_user_found] = any_found
    results[:message] = any_found ? 'User found in one or more tables' : 'User not found in any table'

    render json: results, status: any_found ? :ok : :not_found
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end 