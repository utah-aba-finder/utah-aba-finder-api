class MassNotificationMailer < ApplicationMailer
  def password_update_reminder(provider)
    @provider = provider
    
    mail(
      to: @provider.email,
      subject: "Important: Update Your Autism Services Locator Account - #{provider.name}"
    )
  end

  def system_update_notification(provider)
    @provider = provider
    
    mail(
      to: @provider.email,
      subject: "Welcome to the New Autism Services Locator System - #{provider.name}"
    )
  end
end
