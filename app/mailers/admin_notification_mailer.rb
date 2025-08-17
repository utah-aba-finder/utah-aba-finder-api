class AdminNotificationMailer < ApplicationMailer
  def new_provider_registration(registration)
    @registration = registration
    @admin_email = 'registration@autismserviceslocator.com'
    
    mail(
      to: @admin_email,
      subject: "New Provider Registration: #{registration.provider_name}"
    )
  end
end 