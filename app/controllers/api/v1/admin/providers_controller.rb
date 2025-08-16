class Api::V1::Admin::ProvidersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_super_admin!
  def index
    providers = Provider.all
    render json: ProviderSerializer.format_providers(providers)
  end

  def update
    provider = Provider.find(params[:id])
    if provider.update(admin_provider_params)
      provider.touch # Ensure updated_at is updated
      render json: ProviderSerializer.format_providers([provider])
    else
      render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def ensure_super_admin!
    unless current_user&.role == 'super_admin' || current_user&.role == 0
      render json: { error: 'Access denied. Super admin privileges required.' }, status: :forbidden
    end
  end

  def admin_provider_params
    # Handle both regular params and nested data format
    if params[:data].present?
      params.require(:data).first[:attributes].permit(
        :name,
        :website,
        :email,
        :cost,
        :min_age,
        :max_age,
        :waitlist,
        :telehealth_services,
        :spanish_speakers,
        :at_home_services,
        :in_clinic_services,
        :status,
        :provider_type,
        :in_home_only,
        logo: [],
        service_delivery: {}
      )
    else
      # Handle direct params (for logo uploads)
      params.permit(
        :name,
        :website,
        :email,
        :cost,
        :min_age,
        :max_age,
        :waitlist,
        :telehealth_services,
        :spanish_speakers,
        :at_home_services,
        :in_clinic_services,
        :status,
        :provider_type,
        :in_home_only,
        logo: [],
        service_delivery: {}
      )
    end
  end
end