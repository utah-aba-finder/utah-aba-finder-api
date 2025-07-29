class Api::V1::InsurancesController < ApplicationController
  def index
    insurances = Insurance.all
    render json: InsuranceSerializer.format_insurances(insurances)
  end
  
  def create
    insurance = Insurance.find_or_create_by(name: params.require(:data).first[:attributes][:name])

    if insurance.save
      insurance.initialize_provider_insurance
      render json: InsuranceSerializer.format_insurances([insurance]), status: :created
    else
      render json: { errors: insurance.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def update
    insurance = Insurance.find_by(id: params[:id])
  
    if insurance&.update(insurance_params)
      render json: InsuranceSerializer.format_insurances([insurance])
    else
      render json: { errors: insurance&.errors&.full_messages || ["Insurance not found"] }, status: :unprocessable_entity
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
  def insurance_params
    params.require(:data).first[:attributes].permit(
      :name
    )
  end
end