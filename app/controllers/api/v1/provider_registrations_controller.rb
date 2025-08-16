class Api::V1::ProviderRegistrationsController < ApplicationController
  skip_before_action :authenticate_client, only: [:create, :show]

  def create
    Rails.logger.info "=== PROVIDER REGISTRATION DEBUG ==="
    Rails.logger.info "Raw params: #{params.inspect}"
    Rails.logger.info "Provider registration params: #{params[:provider_registration].inspect}"
    Rails.logger.info "Submitted data: #{params[:provider_registration][:submitted_data].inspect}"
    
    @registration = ProviderRegistration.new(registration_params)
    
    Rails.logger.info "Registration object before save: #{@registration.attributes.inspect}"
    Rails.logger.info "Submitted data before save: #{@registration.submitted_data.inspect}"
    
    if @registration.save
      Rails.logger.info "Registration saved successfully with ID: #{@registration.id}"
      Rails.logger.info "Saved submitted_data: #{@registration.submitted_data.inspect}"
      Rails.logger.info "Final attributes: #{@registration.attributes.inspect}"
      
      # Send confirmation email to provider
      ProviderRegistrationMailer.received(@registration).deliver_later
      
      # Send notification email to admin
      AdminNotificationMailer.new_provider_registration(@registration).deliver_later
      
      render json: {
        success: true,
        message: "Registration submitted successfully! We'll review your information and contact you soon.",
        registration_id: @registration.id
      }, status: :created
    else
      Rails.logger.error "Registration failed to save: #{@registration.errors.full_messages}"
      render json: { 
        success: false,
        errors: @registration.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  def show
    @registration = ProviderRegistration.find(params[:id])
    render json: ProviderRegistrationSerializer.format_registration(@registration)
  end

  def index
    # Only super admins can view all registrations
    unless current_user&.role == 'super_admin'
      render json: { error: "Unauthorized" }, status: :forbidden
      return
    end

    @registrations = ProviderRegistration.recent
    
    # Apply filters
    @registrations = @registrations.where(status: params[:status]) if params[:status].present?
    @registrations = @registrations.where(category: params[:category]) if params[:category].present?
    @registrations = @registrations.where(is_processed: params[:processed]) if params[:processed].present?
    
    render json: ProviderRegistrationSerializer.format_registrations(@registrations)
  end

  def approve
    # Only super admins can approve registrations
    unless current_user&.role == 'super_admin'
      render json: { error: "Unauthorized" }, status: :forbidden
      return
    end

    @registration = ProviderRegistration.find(params[:id])
    
    if @registration.approve!(current_user, params[:admin_notes])
      render json: {
        success: true,
        message: "Registration approved successfully"
      }
    else
      render json: { 
        success: false,
        error: "Registration cannot be approved" 
      }, status: :unprocessable_entity
    end
  end

  def reject
    # Only super admins can reject registrations
    unless current_user&.role == 'super_admin'
      render json: { error: "Unauthorized" }, status: :forbidden
      return
    end

    @registration = ProviderRegistration.find(params[:id])
    
    if params[:rejection_reason].blank?
      render json: { 
        success: false,
        error: "Rejection reason is required" 
      }, status: :bad_request
      return
    end
    
    if @registration.reject!(current_user, params[:rejection_reason], params[:admin_notes])
      render json: {
        success: true,
        message: "Registration rejected successfully"
      }
    else
      render json: { 
        success: false,
        error: "Registration cannot be rejected" 
      }, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    Rails.logger.info "=== REGISTRATION PARAMS DEBUG ==="
    Rails.logger.info "Params before permit: #{params[:provider_registration].inspect}"
    
    permitted_params = params.require(:provider_registration).permit(:email, :provider_name, :category, submitted_data: {})
    
    Rails.logger.info "Params after permit: #{permitted_params.inspect}"
    Rails.logger.info "Submitted data after permit: #{permitted_params[:submitted_data].inspect}"
    
    permitted_params
  end
end 