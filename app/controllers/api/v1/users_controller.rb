class Api::V1::UsersController < ApplicationController
  # Allow both API key and Bearer token authentication
  before_action :authenticate_client, unless: -> { request.headers['Authorization']&.start_with?('Bearer ') }
  before_action :authenticate_user!, if: -> { request.headers['Authorization']&.start_with?('Bearer ') }

  def index
    users = User.all.includes(:provider)
    render json: {
      users: users.map { |user| 
        provider = user.provider
        { 
          id: user.id, 
          email: user.email,
          first_name: user.first_name,
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
        first_name: user.first_name,
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
      
      # Update legacy provider_id relationship
      user.update!(provider_id: provider_id)
      
      # Also create provider_assignment for multi-provider system
      ProviderAssignment.find_or_create_by(
        user: user,
        provider: provider
      ) do |assignment|
        assignment.assigned_by = current_user&.email || user.email
      end
      
      # Set as active provider if user doesn't have one
      user.update!(active_provider_id: provider_id) if user.active_provider_id.nil?
      
      render json: { 
        message: "User successfully linked to provider",
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id,
          active_provider_id: user.active_provider_id
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
    old_provider_id = user.provider_id
    
    # Remove provider_assignment if it exists
    if old_provider_id
      ProviderAssignment.where(user: user, provider_id: old_provider_id).destroy_all
    end
    
    # Clear legacy provider_id
    user.update!(provider_id: nil)
    
    # Clear active_provider if it was the same provider
    if user.active_provider_id == old_provider_id
      user.update!(active_provider_id: nil)
    end
    
    render json: { 
      message: "User successfully unlinked from provider",
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        provider_id: user.provider_id,
        active_provider_id: user.active_provider_id
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
      
      # Update legacy provider_id relationship
      user.update!(provider_id: provider_id)
      
      # Also create provider_assignment for multi-provider system
      ProviderAssignment.find_or_create_by(
        user: user,
        provider: provider
      ) do |assignment|
        assignment.assigned_by = current_user&.email || user.email
      end
      
      # Set as active provider if user doesn't have one
      user.update!(active_provider_id: provider_id) if user.active_provider_id.nil?
      
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
          created_at: user.created_at,
          updated_at: user.updated_at,
          last_sign_in_at: user.last_sign_in_at,
          sign_in_count: user.sign_in_count
        } 
      },
      total_count: users.count
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

  # New endpoint for bulk user assignment
  def bulk_assign_users
    user_ids = params[:user_ids]
    provider_id = params[:provider_id]
    
    if user_ids.blank? || provider_id.blank?
      render json: { error: "Both user_ids and provider_id are required" }, status: :bad_request
      return
    end
    
    begin
      provider = Provider.find(provider_id)
      users = User.where(id: user_ids)
      
      if users.count != user_ids.count
        found_ids = users.pluck(:id)
        missing_ids = user_ids - found_ids
        render json: { 
          error: "Some users not found", 
          missing_user_ids: missing_ids,
          found_user_ids: found_ids
        }, status: :not_found
        return
      end
      
      # Update all users
      updated_users = []
      users.each do |user|
        user.update!(provider_id: provider_id)
        updated_users << {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id
        }
      end
      
      render json: { 
        success: true,
        message: "Successfully assigned #{updated_users.count} users to provider",
        provider: {
          id: provider.id,
          name: provider.name,
          email: provider.email
        },
        users: updated_users
      }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Provider not found with ID: #{provider_id}" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # New endpoint to assign user by email
  def assign_user_by_email
    user_email = params[:user_email]
    provider_id = params[:provider_id]
    
    if user_email.blank? || provider_id.blank?
      render json: { error: "Both user_email and provider_id are required" }, status: :bad_request
      return
    end
    
    begin
      user = User.find_by(email: user_email)
      provider = Provider.find(provider_id)
      
      if user.nil?
        render json: { error: "User not found with email: #{user_email}" }, status: :not_found
        return
      end
      
      old_provider_id = user.provider_id
      old_provider = old_provider_id ? Provider.find(old_provider_id) : nil
      
      user.update!(provider_id: provider_id)
      
      render json: { 
        success: true,
        message: "User successfully assigned to provider",
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
    if search.present?
      users = users.where("email ILIKE ? OR first_name ILIKE ?", "%#{search}%", "%#{search}%")
    end
    
    # Pagination
    total_count = users.count
    users = users.offset((page.to_i - 1) * per_page.to_i).limit(per_page.to_i)
    
    render json: {
      users: users.map { |user| 
        provider = user.provider
        { 
          id: user.id, 
          email: user.email,
          first_name: user.first_name,
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

  # New method to unassign a provider from a user
  def unassign_provider_from_user
    provider_id = params[:provider_id]
    
    begin
      provider = Provider.find(provider_id)
      
      # Find users linked via old system
      users_linked_via_old_system = User.where(provider_id: provider_id)
      
      # Find user linked via new system
      user_linked_via_new_system = provider.user
      
      # Unlink from old system
      users_linked_via_old_system.update_all(provider_id: nil) if users_linked_via_old_system.any?
      
      # Unlink from new system
      provider.update!(user_id: nil) if user_linked_via_new_system
      
      render json: { 
        success: true,
        message: "Provider successfully unassigned from all users",
        provider: {
          id: provider.id,
          name: provider.name,
          email: provider.email
        },
        unlinked_users_old_system: users_linked_via_old_system.map { |u| { id: u.id, email: u.email } },
        unlinked_user_new_system: user_linked_via_new_system ? { id: user_linked_via_new_system.id, email: user_linked_via_new_system.email } : nil
      }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Provider not found" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # New method to unlink a user from a provider (alternative endpoint)
  def unlink_user_from_provider
    user_email = params[:user_email]
    provider_id = params[:provider_id]
    
    begin
      user = User.find_by(email: user_email)
      provider = Provider.find(provider_id)
      
      if user.nil?
        render json: { error: "User not found with email: #{user_email}" }, status: :not_found
        return
      end
      
      # Check all linking methods
      linked_via_old_system = user.provider_id.to_i == provider_id.to_i
      linked_via_new_system = provider.user_id == user.id
      linked_via_assignment = ProviderAssignment.exists?(user: user, provider: provider)
      
      if linked_via_old_system || linked_via_new_system || linked_via_assignment
        # Unlink from old system (legacy provider_id)
        if linked_via_old_system
          user.update!(provider_id: nil)
        end
        
        # Unlink from new system (provider.user_id)
        if linked_via_new_system
          provider.update!(user_id: nil)
        end
        
        # Remove provider_assignment
        if linked_via_assignment
          ProviderAssignment.where(user: user, provider: provider).destroy_all
        end
        
        # Clear active_provider if it was this provider
        if user.active_provider_id.to_i == provider_id.to_i
          user.update!(active_provider_id: nil)
        end
        
        render json: { 
          success: true,
          message: "User successfully unlinked from provider",
          user: {
            id: user.id,
            email: user.email
          },
          provider: {
            id: provider.id,
            name: provider.name,
            email: provider.email
          },
          unlinked_from_old_system: linked_via_old_system,
          unlinked_from_new_system: linked_via_new_system,
          unlinked_from_assignment: linked_via_assignment
        }, status: :ok
      else
        render json: { error: "User is not linked to this provider" }, status: :bad_request
      end
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Provider not found" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :provider_id)
  end
end 