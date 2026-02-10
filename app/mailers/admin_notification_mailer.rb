class AdminNotificationMailer < ApplicationMailer
  def new_provider_registration(registration)
    @registration = registration
    # Use environment variable if set, otherwise default to jordanwilliamson@autismserviceslocator.com
    @admin_email = ENV['ADMIN_NOTIFICATION_EMAIL'] || 'jordanwilliamson@autismserviceslocator.com'
    
    # Optionally CC the old registration email for backup
    cc_emails = []
    if ENV['ADMIN_NOTIFICATION_CC'].present?
      cc_emails = ENV['ADMIN_NOTIFICATION_CC'].split(',').map(&:strip)
    end
    
    mail(
      to: @admin_email,
      cc: cc_emails.presence,
      subject: "New Provider Registration: #{registration.provider_name}"

    )
  end
  
  def new_provider_claim_request(claim_request)
    @claim_request = claim_request
    @provider = claim_request.provider
    @admin_email = ENV['ADMIN_NOTIFICATION_EMAIL'] || 'jordanwilliamson@autismserviceslocator.com'
    
    # Optionally CC the old registration email for backup
    cc_emails = []
    if ENV['ADMIN_NOTIFICATION_CC'].present?
      cc_emails = ENV['ADMIN_NOTIFICATION_CC'].split(',').map(&:strip)
    end
    
    provider_name = @provider&.name || 'Unknown Provider'
    
    mail(
      to: @admin_email,
      cc: cc_emails.presence,
      subject: "New Provider Account Claim Request: #{provider_name}"
    )
  end
  
  def password_changed(user)
    @user = user
    @provider = user.provider
    @admin_email = ENV['ADMIN_NOTIFICATION_EMAIL'] || 'jordanwilliamson@autismserviceslocator.com'
    
    # Optionally CC the old registration email for backup
    cc_emails = []
    if ENV['ADMIN_NOTIFICATION_CC'].present?
      cc_emails = ENV['ADMIN_NOTIFICATION_CC'].split(',').map(&:strip)
    end
    
    provider_name = @provider&.name || 'No Provider Linked'
    
    mail(
      to: @admin_email,
      cc: cc_emails.presence,
      subject: "Password Changed: #{user.email} (#{provider_name})"
    )
  end
end 