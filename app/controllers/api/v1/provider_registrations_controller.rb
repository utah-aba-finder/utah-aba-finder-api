class Api::V1::ProviderRegistrationsController < ApplicationController
  skip_before_action :authenticate_client, only: [:create, :show]
  
  def index
    # Super admin only
    authenticate_user!
    unless current_user&.role == 'super_admin'
      render json: { error: 'Unauthorized' }, status: :forbidden
      return
    end

    registrations = ProviderRegistration.includes(:reviewed_by).order(created_at: :desc)
    render json: ProviderRegistrationSerializer.format_registrations(registrations)
  end

  def show
    registration = ProviderRegistration.find(params[:id])
    render json: ProviderRegistrationSerializer.format_registration(registration)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Registration not found' }, status: :not_found
  end

  def create
    registration = ProviderRegistration.new(registration_params)
    
    if registration.save
      # Send notification email to admin
      AdminNotificationMailer.new_provider_registration(registration).deliver_later
      
      # Send confirmation email to provider
      ProviderRegistrationMailer.received(registration).deliver_later
      
      render json: ProviderRegistrationSerializer.format_registration(registration), status: :created
    else
      render json: { error: registration.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def approve
    # Super admin only
    authenticate_user!
    unless current_user&.role == 'super_admin'
      render json: { error: 'Unauthorized' }, status: :forbidden
      return
    end

    registration = ProviderRegistration.find(params[:id])
    notes = params[:admin_notes]
    
    if registration.approve!(current_user, notes)
      render json: { message: 'Registration approved successfully' }
    else
      render json: { error: 'Registration could not be approved' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Registration not found' }, status: :not_found
  end

  def reject
    # Super admin only
    authenticate_user!
    unless current_user&.role == 'super_admin'
      render json: { error: 'Unauthorized' }, status: :forbidden
      return
    end

    registration = ProviderRegistration.find(params[:id])
    reason = params[:rejection_reason]
    notes = params[:admin_notes]
    
    if registration.reject!(current_user, reason, notes)
      render json: { message: 'Registration rejected successfully' }
    else
      render json: { error: 'Registration could not be rejected' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Registration not found' }, status: :not_found

  end

  private

  def registration_params
    params.permit(:email, :provider_name, :category, submitted_data: {})
  end
end 