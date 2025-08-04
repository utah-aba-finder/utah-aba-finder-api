class Api::V1::UsersController < ApplicationController
  before_action :authenticate_client

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

  def show
    user = User.find(params[:id])
    render json: {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        provider_id: user.provider_id,
        created_at: user.created_at
      }
    }, status: :ok
  end

  def create
    user = User.new(user_params)
    if user.save
      render json: { message: 'User created successfully', user: user }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # New action for manually linking users to providers
  def link_to_provider
    user = User.find(params[:user_id])
    provider = Provider.find(params[:provider_id])
    
    user.update!(provider_id: provider.id)
    
    render json: { 
      message: "User #{user.email} linked to provider #{provider.name}",
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        provider_id: user.provider_id
      }
    }, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # New action to unlink user from provider
  def unlink_from_provider
    user = User.find(params[:user_id])
    
    user.update!(provider_id: nil)
    
    render json: { 
      message: "User #{user.email} unlinked from provider",
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        provider_id: user.provider_id
      }
    }, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def check_user_exists
    user = User.find_by(email: params[:email])
    if user
      render json: { 
        exists: true, 
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id
        }
      }
    else
      render json: { exists: false }
    end
  end

  def debug_lookup
    user = User.find_by(email: params[:email])
    if user
      render json: { 
        found: true, 
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id,
          encrypted_password: user.encrypted_password.present? ? 'Set' : 'Not set'
        }
      }
    else
      render json: { found: false }
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :provider_id)
  end
end 