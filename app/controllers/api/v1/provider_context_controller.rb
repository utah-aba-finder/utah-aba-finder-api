class Api::V1::ProviderContextController < ApplicationController
  before_action :authenticate_user!
  
  # POST /api/v1/provider_context
  def set
    provider_id = params.require(:provider_id)
    
    unless @current_user.can_access_provider?(provider_id)
      render json: { error: "Forbidden - You don't have access to this provider" }, status: :forbidden
      return
    end
    
    @current_user.set_active_provider(provider_id)
    
    render json: { 
      success: true,
      active_provider_id: provider_id,
      message: "Active provider context updated"
    }
  rescue ActionController::ParameterMissing => e
    render json: { error: "Provider ID is required" }, status: :bad_request
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  # GET /api/v1/provider_context
  def show
    active_provider = @current_user.active_provider
    
    if active_provider
      render json: {
        active_provider_id: active_provider.id,
        active_provider_name: active_provider.name,
        is_primary_owner: @current_user.primary_owner_of?(active_provider),
        is_assigned: @current_user.assigned_to?(active_provider)
      }
    else
      render json: { 
        active_provider_id: nil,
        message: "No active provider context set"
      }
    end
  end
end 