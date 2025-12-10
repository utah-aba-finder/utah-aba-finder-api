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
    begin
      user = User.find(params[:id])
      update_params = admin_user_params
      
      Rails.logger.info "Updating user #{user.id} (#{user.email}) with params: #{update_params.inspect}"
      
      if user.update(update_params)
        # Reload to get fresh data from database
        user.reload
        
        Rails.logger.info "User updated successfully. first_name: #{user.respond_to?(:first_name) ? user.first_name.inspect : 'N/A'}"
        
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
        Rails.logger.error "User update failed: #{user.errors.full_messages}"
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "User not found" }, status: :not_found
    rescue => e
      Rails.logger.error "Error in admin users update: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An error occurred while updating user: #{e.message}" }, status: :internal_server_error
    end
  end

  # Assign user to multiple providers
  def assign_providers
    begin
      user_email = params[:user_email] || params[:email]
      provider_ids = params[:provider_ids] || []
      
      if user_email.blank?
        render json: { error: "user_email is required" }, status: :bad_request
        return
      end
      
      if provider_ids.blank? || !provider_ids.is_a?(Array) || provider_ids.empty?
        render json: { error: "provider_ids must be a non-empty array" }, status: :bad_request
        return
      end
      
      user = User.find_by(email: user_email)
      if user.nil?
        render json: { error: "User not found with email: #{user_email}" }, status: :not_found
        return
      end
      
      # Find all providers
      providers = Provider.where(id: provider_ids)
      if providers.count != provider_ids.count
        found_ids = providers.pluck(:id)
        missing_ids = provider_ids.map(&:to_i) - found_ids
        render json: { 
          error: "Some providers not found", 
          missing_provider_ids: missing_ids,
          found_provider_ids: found_ids
        }, status: :not_found
        return
      end
      
      # Create assignments for each provider
      assignments = []
      errors = []
      
      providers.each do |provider|
        # Check if assignment already exists (not checking all access methods, just assignments)
        existing_assignment = ProviderAssignment.find_by(user: user, provider: provider)
        if existing_assignment
          errors << {
            provider_id: provider.id,
            provider_name: provider.name,
            error: "User already assigned to this provider",
            assignment_id: existing_assignment.id
          }
          next
        end
        
        # Create assignment
        begin
          assignment = ProviderAssignment.create!(
            user: user,
            provider: provider,
            assigned_by: current_user&.email || user.email
          )
          
          assignments << {
            id: assignment.id,
            provider_id: provider.id,
            provider_name: provider.name,
            assigned_at: assignment.created_at
          }
        rescue ActiveRecord::RecordInvalid => e
          errors << {
            provider_id: provider.id,
            provider_name: provider.name,
            error: e.message
          }
        end
      end
      
      # Reload user to get updated provider count
      user.reload
      
      render json: {
        success: true,
        message: "Successfully assigned user to #{assignments.count} provider(s)",
        user: {
          id: user.id,
          email: user.email,
          accessible_providers_count: user.all_managed_providers.count
        },
        assignments: assignments,
        errors: errors,
        summary: {
          total_requested: provider_ids.count,
          successful: assignments.count,
          failed: errors.count
        }
      }, status: :ok
    rescue => e
      Rails.logger.error "Error in admin users assign_providers: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An error occurred while assigning providers: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  def admin_user_params
    permitted = [:email, :role, :provider_id]
    # Check if first_name column exists in the database
    if User.column_names.include?('first_name')
      permitted << :first_name
      Rails.logger.info "first_name column exists, allowing first_name updates"
    else
      Rails.logger.warn "first_name column does not exist in users table"
    end
    params.require(:user).permit(*permitted)
  end
end
