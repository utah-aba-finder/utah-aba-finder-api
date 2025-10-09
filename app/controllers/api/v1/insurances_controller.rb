class Api::V1::InsurancesController < ApplicationController
  # Allow authenticated users or API keys to access insurances
  skip_before_action :authenticate_client, only: [:index, :search]
  before_action :authenticate_user_or_client, only: [:index, :search]

  def index
    insurances = Insurance.all
    render json: InsuranceSerializer.format_insurances(insurances)
  end
  
  def search
    query = params[:q]
    if query.present?
      insurances = InsuranceService.search_insurances(query)
      render json: InsuranceSerializer.format_insurances(insurances)
    else
      # Return popular insurances if no query
      # Note: This list is sorted by usage and stable for 24h (cache at the edge)
      insurances = InsuranceService.get_popular_insurances(20)
      render json: InsuranceSerializer.format_insurances(insurances)
    end
  rescue => e
    Rails.logger.error "Insurance search failed: #{e.message}"
    render json: { 
      errors: [{ 
        source: { pointer: "/data" }, 
        detail: "Insurance search failed. Please try again." 
      }] 
    }, status: :internal_server_error
  end
  
  def create
    insurance = Insurance.find_or_create_by(name: params.require(:data).first[:attributes][:name])

    if insurance.save
      insurance.initialize_provider_insurance
      render json: InsuranceSerializer.format_insurances([insurance]), status: :created
    else
      render json: { 
        errors: insurance.errors.map do |field, message|
          {
            source: { pointer: "/data/attributes/#{field}" },
            detail: message
          }
        end
      }, status: :unprocessable_entity
    end
  end
  
  def update
    insurance = Insurance.find_by(id: params[:id])
  
    if insurance&.update(insurance_params)
      render json: InsuranceSerializer.format_insurances([insurance])
    else
      render json: { 
        errors: insurance&.errors&.map do |field, message|
          {
            source: { pointer: "/data/attributes/#{field}" },
            detail: message
          }
        end || [{ source: { pointer: "/data" }, detail: "Insurance not found" }]
      }, status: :unprocessable_entity
    end
  end

  def destroy
    insurance = Insurance.find_by(id: params[:id])
    if insurance
      deleted_name = insurance.name
      insurance.destroy
      render json: { message: "Insurance '#{deleted_name}' successfully deleted" }
    else
      render json: { error: "Insurance not found" }, status: :not_found
    end
  end

  private
  
  def authenticate_user_or_client
    auth = request.headers['Authorization'].to_s
    
    # Check for Bearer token (user authentication)
    if auth.start_with?('Bearer ')
      token = auth.sub(/^Bearer\s+/, '')
      user = User.find_by(id: token)
      if user
        @current_user = user
        return
      end
    end
    
    # Check for API key (client authentication)
    client = Client.find_by(api_key: auth)
    if client
      @current_client = client
      return
    end
    
    # If neither authentication method works, return unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
  
  def insurance_params
    params.require(:data).first[:attributes].permit(
      :name
    )
  end
end