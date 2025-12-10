class Api::V1::ProviderAssignmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_assignment, only: [:create, :destroy]
  
  # POST /api/v1/provider_assignments
  def create
    user = User.find(params[:user_id])
    provider = Provider.find(params[:provider_id])
    
    # Check if assignment already exists
    if ProviderAssignment.exists?(user: user, provider: provider)
      render json: { 
        success: true, 
        message: "Provider already assigned to user",
        provider_assignment: {
          user_id: user.id,
          provider_id: provider.id
        }
      }, status: :ok
      return
    end
    
    # Create the assignment
    assignment = ProviderAssignment.create!(
      user: user, 
      provider: provider,
      assigned_by: current_user&.email || user.email
    )
    
    render json: { 
      success: true,
      message: "Provider successfully assigned to user",
      provider_assignment: {
        id: assignment.id,
        user_id: user.id,
        user_email: user.email,
        provider_id: provider.id,
        provider_name: provider.name
      }
    }, status: :created
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "User or Provider not found" }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  # DELETE /api/v1/provider_assignments
  def destroy
    user = User.find(params[:user_id])
    provider = Provider.find(params[:provider_id])
    
    assignment = ProviderAssignment.find_by!(user: user, provider: provider)
    assignment.destroy!
    
    render json: { 
      success: true,
      message: "Provider successfully unassigned from user"
    }, status: :no_content
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Assignment not found" }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  # GET /api/v1/provider_assignments
  def index
    if current_user&.role == 'super_admin'
      # Super admins can see all assignments
      assignments = ProviderAssignment.includes(:user, :provider)
        .order(created_at: :desc)
        .page(params[:page])
        .per(params[:per_page] || 25)
      
      render json: {
        data: assignments.map do |assignment|
          {
            id: assignment.id,
            user: {
              id: assignment.user.id,
              email: assignment.user.email
            },
            provider: {
              id: assignment.provider.id,
              name: assignment.provider.name
            },
            assigned_at: assignment.created_at
          }
        end,
        meta: {
          total_count: assignments.total_count,
          page: assignments.current_page,
          per_page: assignments.limit_value
        }
      }
    else
      render json: { error: "Access denied" }, status: :forbidden
    end
  end
  
  private
  
  def authorize_assignment
    # Only super admins can assign/unassign providers
    unless current_user&.role == 'super_admin'
      render json: { error: 'Access denied. Only super admins can manage provider assignments.' }, status: :forbidden
      return
    end
  end
end 