class ProviderRegistrationMailer < ApplicationMailer
  def received(registration)
    @registration = registration
    
    mail(
      to: @registration.email,
      subject: "Provider Registration Received - #{registration.provider_name}"

    )
  end

  def approved(registration)
    @registration = registration
    
    mail(
      to: @registration.email,
      subject: "Provider Registration Approved - #{registration.provider_name}"

    )
  end

  def approved_with_credentials(registration, user)
    @registration = registration
    @user = user
    @password = user.instance_variable_get(:@plain_password)
    
    mail(
      to: @registration.email,
      subject: "Welcome! Your Provider Account is Ready - #{registration.provider_name}"
    )
  end

  def rejected(registration)
    @registration = registration
    
    mail(
      to: @registration.email,
      subject: "Provider Registration Update - #{registration.provider_name}"

    )
  end

  def admin_created_provider(provider, user)
    @provider = provider
    @user = user
    @password = user.instance_variable_get(:@plain_password)
    
    mail(
      to: @provider.email,
      subject: "Welcome! Your Provider Account Has Been Created - #{provider.name}"
    )
  end
end 