class ProviderRegistrationMailer < ApplicationMailer
  def received(registration)
    @registration = registration
    mail(
      to: @registration.email,
      subject: "Provider Registration Received - #{@registration.provider_name}"
    )
  end

  def approved(registration)
    @registration = registration
    mail(
      to: @registration.email,
      subject: "Provider Registration Approved - #{@registration.provider_name}"
    )
  end

  def rejected(registration)
    @registration = registration
    mail(
      to: @registration.email,
      subject: "Provider Registration Update - #{@registration.provider_name}"
    )
  end
end 