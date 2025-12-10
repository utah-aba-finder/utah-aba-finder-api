class Api::V1::Admin::UsersController < Api::V1::Admin::BaseController
  def index
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

  def update
    user = User.find(params[:id])
    
    if user.update(admin_user_params)
      render json: {
        message: 'User updated successfully',
        user: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
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
    params.require(:user).permit(:email, :first_name, :role, :provider_id)
  end
end
