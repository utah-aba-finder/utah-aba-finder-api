class Api::V1::Admin::UsersController < Api::V1::Admin::BaseController
  def index
    begin
      page = params[:page] || 1
      per_page = params[:per_page] || 25
      role_filter = params[:role]
      provider_filter = params[:provider_id]
      search = params[:search]
      
      users = User.all
      
      # Apply filters
      users = users.where(role: role_filter) if role_filter.present?
      users = users.where(provider_id: provider_filter) if provider_filter.present?
      if search.present?
        # Check if first_name column exists in the database
        if User.column_names.include?('first_name')
          users = users.where("email ILIKE ? OR COALESCE(first_name, '') ILIKE ?", "%#{search}%", "%#{search}%")
        else
          users = users.where("email ILIKE ?", "%#{search}%")
        end
      end
      
      # Pagination
      total_count = users.count
      users = users.offset((page.to_i - 1) * per_page.to_i).limit(per_page.to_i)
      
      render json: {
        users: users.map { |user| 
          provider = nil
          if user.provider_id.present?
            begin
              provider = Provider.find_by(id: user.provider_id)
            rescue => e
              Rails.logger.warn "Provider #{user.provider_id} not found for user #{user.id}: #{e.message}"
            end
          end
          
          { 
            id: user.id, 
            email: user.email,
            first_name: user.respond_to?(:first_name) ? user.first_name : nil,
            role: user.role,
            provider_id: user.provider_id,
            provider_name: provider&.name,
            provider_email: provider&.email,
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
    rescue => e
      Rails.logger.error "Error in admin users index: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An error occurred while fetching users: #{e.message}" }, status: :internal_server_error
    end
  end

  def show
    begin
      user = User.find(params[:id])
      provider = nil
      if user.provider_id.present?
        begin
          provider = Provider.find_by(id: user.provider_id)
        rescue => e
          Rails.logger.warn "Provider #{user.provider_id} not found for user #{user.id}: #{e.message}"
        end
      end
      
      render json: {
        user: {
          id: user.id,
          email: user.email,
          first_name: user.respond_to?(:first_name) ? user.first_name : nil,
          role: user.role,
          provider_id: user.provider_id,
          provider_name: provider&.name,
          provider_email: provider&.email,
          created_at: user.created_at,
          updated_at: user.updated_at,
          last_sign_in_at: user.last_sign_in_at,
          sign_in_count: user.sign_in_count
        }
      }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "User not found" }, status: :not_found
    rescue => e
      Rails.logger.error "Error in admin users show: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An error occurred while fetching user: #{e.message}" }, status: :internal_server_error
    end
  end

  def update
    user = User.find(params[:id])
    
    if user.update(admin_user_params)
      render json: {
        message: 'User updated successfully',
        user: {
          id: user.id,
          email: user.email,
          first_name: user.respond_to?(:first_name) ? user.first_name : nil,
          role: user.role,
          provider_id: user.provider_id,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def admin_user_params
    permitted = [:email, :role, :provider_id]
    permitted << :first_name if User.column_names.include?('first_name')
    params.require(:user).permit(*permitted)
  end
end
