class AdminNotificationMailer < ApplicationMailer
  def new_provider_registration(registration)
    @registration = registration
    mail(
      to: "registration@autismserviceslocator.com",
      subject: "New Provider Registration: #{@registration.provider_name}"
    )
  end
end 