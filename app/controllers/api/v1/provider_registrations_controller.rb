class Api::V1::ProviderRegistrationsController < ApplicationController
  # This endpoint should be public
  skip_before_action :authenticate_client, only: [:create, :show]

  # Ensure JSON keys are underscored
  before_action :underscore_params!
  before_action :load_mailers
  
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
    # Check idempotency key
    idempotency_key = request.headers['Idempotency-Key']
    if idempotency_key.present?
      existing_registration = ProviderRegistration.find_by(idempotency_key: idempotency_key)
      if existing_registration
        render json: ProviderRegistrationSerializer.format_registration(existing_registration), 
               status: :ok,
               headers: { 'Location' => "/api/v1/provider_registrations/#{existing_registration.id}" }
        return
      end
    end

    registration = ProviderRegistration.new(reg_params)
    
    # Debug logging
    Rails.logger.info "[Controller Debug] reg_params=#{reg_params.to_h}"
    
    # Set idempotency key if provided
    registration.idempotency_key = idempotency_key if idempotency_key.present?
    
    if registration.save
      # Send notification email to admin (use deliver_now since no background job queue is configured)
      begin
        admin_email = ENV['ADMIN_NOTIFICATION_EMAIL'] || 'jordanwilliamson@autismserviceslocator.com'
        Rails.logger.info "📧 Sending admin notification email to: #{admin_email}"
        Rails.logger.info "📧 Registration details: ID=#{registration.id}, Name=#{registration.provider_name}, Email=#{registration.email}"
        
        mail = AdminNotificationMailer.new_provider_registration(registration)
        Rails.logger.info "📧 Email prepared - To: #{mail.to.inspect}, CC: #{mail.cc.inspect}, Subject: #{mail.subject}"
        
        mail.deliver_now
        Rails.logger.info "✅ Admin notification email sent successfully for registration #{registration.id}"
      rescue => email_error
        Rails.logger.error "❌ Failed to send admin notification email: #{email_error.class} - #{email_error.message}"
        Rails.logger.error "Email error backtrace: #{email_error.backtrace.first(5).join("\n")}"
        # Continue - registration is saved even if email fails
      end
      
      # Send confirmation email to provider (use deliver_now since no background job queue is configured)
      begin
        ProviderRegistrationMailer.received(registration).deliver_now
        Rails.logger.info "Provider confirmation email sent for registration #{registration.id}"
      rescue => email_error
        Rails.logger.error "⚠️ Failed to send provider confirmation email: #{email_error.message}"
        # Continue - registration is saved even if email fails
      end
      
      render json: ProviderRegistrationSerializer.format_registration(registration), 
             status: :created,
             headers: { 'Location' => "/api/v1/provider_registrations/#{registration.id}" }
    else
      render json: format_errors(registration), status: :unprocessable_entity
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
    
    # Check if registration can be approved before attempting
    unless registration.can_be_approved?
      render json: { 
        error: 'Registration could not be approved',
        details: {
          status: registration.status,
          is_processed: registration.is_processed,
          message: registration.status == 'approved' ? 'Registration has already been approved' : 
                   registration.is_processed ? 'Registration has already been processed' : 
                   'Registration is not in a pending state'
        }
      }, status: :unprocessable_entity
      return
    end
    
    if registration.approve!(current_user, notes)
      render json: { message: 'Registration approved successfully' }
    else
      # Include error messages from the model
      error_messages = registration.errors.full_messages
      Rails.logger.error "Approval failed for registration #{registration.id}: #{error_messages.join(', ')}"
      
      render json: { 
        error: 'Registration could not be approved',
        details: error_messages.any? ? error_messages : ['Unknown error occurred during approval']
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Registration not found' }, status: :not_found
  rescue => e
    Rails.logger.error "Unexpected error in approve: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    render json: { 
      error: 'An unexpected error occurred',
      details: [e.message]
    }, status: :internal_server_error
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

  def load_mailers
    # Ensure mailers are loaded in the API namespace
    AdminNotificationMailer
    ProviderRegistrationMailer
  end

  # Allow array for service_types and arbitrary nested JSON for submitted_data
  def reg_params
    params.require(:provider_registration).permit(
      :email,
      :provider_name,
      :category,               # optional; callback fills if blank
      service_types: [],       # <-- THIS is the key fix
      submitted_data: {}       # <-- allow nested shape
      # If you intend to accept base64 logo right now, also permit :logo_data and decode in model/service
      # :logo_data
    )
  end

  # Make sure camelCase → snake_case (in case the frontend sends camel)
  def underscore_params!
    params.deep_transform_keys!(&:underscore)
  end

  def format_errors(record)
    {
      errors: record.errors.map do |e|
        { source: { pointer: "/data/attributes/#{e.attribute}" }, detail: e.message }
      end
    }
  end
end 