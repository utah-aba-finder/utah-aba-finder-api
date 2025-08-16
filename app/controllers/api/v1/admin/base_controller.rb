class Api::V1::Admin::BaseController < ApplicationController
  skip_before_action :authenticate_client
  before_action :authenticate_user!
  before_action :ensure_super_admin!

  private

  def ensure_super_admin!
    unless current_user&.role == 'super_admin' || current_user&.role == 0
      render json: { error: 'Access denied. Super admin privileges required.' }, status: :forbidden
    end
  end
end 