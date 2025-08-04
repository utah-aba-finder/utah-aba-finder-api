class Api::V1::UsersController < ApplicationController
  before_action :authenticate_client

  def index
    users = User.all.includes(:provider)
    render json: {
      users: users.map { |user| 
        provider = user.provider
        { 
          id: user.id, 
          email: user.email, 
          role: user.role,
          provider_id: user.provider_id,
          provider_name: provider ? provider.name : nil,
          provider_email: provider ? provider.email : nil,
          created_at: user.created_at,
          updated_at: user.updated_at
        } 
      },
      total_count: users.count,
      linked_users: users.where.not(provider_id: nil).count,
      unlinked_users: users.where(provider_id: nil).count
    }, status: :ok
  end

  def show
    user = User.includes(:provider).find(params[:id])
    provider = user.provider
    
    render json: {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        provider_id: user.provider_id,
        provider_name: provider ? provider.name : nil,
        provider_email: provider ? provider.email : nil,
        created_at: user.created_at,
        updated_at: user.updated_at,
        last_sign_in_at: user.last_sign_in_at,
        sign_in_count: user.sign_in_count
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

  def check_user_exists
    email = params[:email]
    user = User.find_by(email: email)
    
    if user
      render json: { 
        exists: true, 
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id
        }
      }, status: :ok
    else
      render json: { exists: false }, status: :ok
    end
  end

  def debug_lookup
    email = params[:email]
    user = User.find_by(email: email)
    
    if user
      render json: { 
        found: true, 
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id
        }
      }, status: :ok
    else
      render json: { found: false, message: "No user found with email: #{email}" }, status: :ok
    end
  end

  def link_to_provider
    user = User.find(params[:id])
    provider_id = params[:provider_id]
    
    begin
      provider = Provider.find(provider_id)
      user.update!(provider_id: provider_id)
      
      render json: { 
        message: "User successfully linked to provider",
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id
        },
        provider: {
          id: provider.id,
          name: provider.name,
          email: provider.email
        }
      }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Provider not found with ID: #{provider_id}" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def unlink_from_provider
    user = User.find(params[:id])
    user.update!(provider_id: nil)
    
    render json: { 
      message: "User successfully unlinked from provider",
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        provider_id: user.provider_id
      }
    }, status: :ok
  end

  # New endpoint for frontend manual linking
  def manual_link
    user_email = params[:user_email]
    provider_id = params[:provider_id]
    
    begin
      user = User.find_by(email: user_email)
      provider = Provider.find(provider_id)
      
      if user.nil?
        render json: { error: "User not found with email: #{user_email}" }, status: :not_found
        return
      end
      
      user.update!(provider_id: provider_id)
      
      render json: { 
        success: true,
        message: "User successfully linked to provider",
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id
        },
        provider: {
          id: provider.id,
          name: provider.name,
          email: provider.email
        }
      }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Provider not found with ID: #{provider_id}" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # New endpoint to get all unlinked users
  def unlinked_users
    users = User.where(provider_id: nil)
    render json: {
      users: users.map { |user| 
        { 
          id: user.id, 
          email: user.email, 
          role: user.role,
          created_at: user.created_at 
        } 
      }
    }, status: :ok
  end

  # New endpoint to get all providers
  def providers_list
    providers = Provider.all
    render json: {
      providers: providers.map { |provider| 
        { 
          id: provider.id, 
          name: provider.name, 
          email: provider.email 
        } 
      }
    }, status: :ok
  end

  # New endpoint to switch a user from one provider to another
  def switch_provider
    user_email = params[:user_email]
    new_provider_id = params[:new_provider_id]
    
    begin
      user = User.find_by(email: user_email)
      
      if user.nil?
        render json: { error: "User not found with email: #{user_email}" }, status: :not_found
        return
      end
      
      new_provider = Provider.find(new_provider_id)
      old_provider_id = user.provider_id
      old_provider = old_provider_id ? Provider.find(old_provider_id) : nil
      
      user.update!(provider_id: new_provider_id)
      
      render json: { 
        success: true,
        message: "User successfully switched providers",
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id
        },
        old_provider: old_provider ? {
          id: old_provider.id,
          name: old_provider.name,
          email: old_provider.email
        } : nil,
        new_provider: {
          id: new_provider.id,
          name: new_provider.name,
          email: new_provider.email
        }
      }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Provider not found with ID: #{new_provider_id}" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # New endpoint to get all users with their current provider associations
  def users_with_providers
    users = User.all.includes(:provider)
    render json: {
      users: users.map { |user| 
        provider = user.provider
        { 
          id: user.id, 
          email: user.email, 
          role: user.role,
          provider_id: user.provider_id,
          provider_name: provider ? provider.name : nil,
          provider_email: provider ? provider.email : nil,
          created_at: user.created_at 
        } 
      }
    }, status: :ok
  end

  # New endpoint for comprehensive user management with filtering
  def admin_users
    page = params[:page] || 1
    per_page = params[:per_page] || 25
    role_filter = params[:role]
    provider_filter = params[:provider_id]
    search = params[:search]
    
    users = User.includes(:provider)
    
    # Apply filters
    users = users.where(role: role_filter) if role_filter.present?
    users = users.where(provider_id: provider_filter) if provider_filter.present?
    users = users.where("email ILIKE ?", "%#{search}%") if search.present?
    
    # Pagination
    total_count = users.count
    users = users.offset((page.to_i - 1) * per_page.to_i).limit(per_page.to_i)
    
    render json: {
      users: users.map { |user| 
        provider = user.provider
        { 
          id: user.id, 
          email: user.email, 
          role: user.role,
          provider_id: user.provider_id,
          provider_name: provider ? provider.name : nil,
          provider_email: provider ? provider.email : nil,
          created_at: user.created_at,
          updated_at: user.updated_at,
          last_sign_in_at: user.last_sign_in_at,
          sign_in_count: user.sign_in_count
        } 
      },
      pagination: {
        page: page.to_i,
        per_page: per_page.to_i,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page.to_i).ceil
      },
      filters: {
        role: role_filter,
        provider_id: provider_filter,
        search: search
      }
    }, status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :provider_id)
  end
end 