class Api::V1::Admin::BaseController < ApplicationController
  skip_before_action :authenticate_client
  before_action :authenticate_user!
  before_action :ensure_super_admin!
  before_action :log_memory_usage

  private

  def ensure_super_admin!
    unless current_user&.role == 'super_admin' || current_user&.role == 0
      render json: { error: 'Access denied. Super admin privileges required.' }, status: :forbidden
    end
  end
  
  def log_memory_usage
    begin
      MemoryMonitor.log_memory_usage("#{self.class.name}##{action_name}")
    rescue => e
      Rails.logger.warn "MemoryMonitor error: #{e.message}"
      # Don't fail the request if memory monitoring fails
    end
  end
end 