class Api::V1::Admin::ProvidersController < Api::V1::Admin::BaseController
  def index
    providers = Provider.all
    render json: ProviderSerializer.format_providers(providers)
  end

  def update
    provider = Provider.find(params[:id])
    
    # Handle practice types separately if provided
    practice_type_params = nil
    if params[:data]&.first&.dig(:attributes, :provider_type)&.present?
      practice_type_params = params[:data].first[:attributes][:provider_type]
    elsif params[:provider_type].present?
      practice_type_params = params[:provider_type]
    end
    
    if provider.update(admin_provider_params)
      # Update practice types if provided
      if practice_type_params.present?
        provider.update_practice_types(practice_type_params)
      end
      
      provider.touch # Ensure updated_at is updated
      render json: ProviderSerializer.format_providers([provider])
    else
      render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

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
        :in_home_only,
        logo: [],
        service_delivery: {}
      )
    end
  end
end