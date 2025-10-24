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
    
    # Get template from database
    html_template = EmailTemplate.find_by(name: 'admin_created_provider', template_type: 'html')
    text_template = EmailTemplate.find_by(name: 'admin_created_provider', template_type: 'text')
    
    # Use database template if available, otherwise fall back to file-based
    if html_template
      # Render the database template content
      html_content = render_template_content(html_template.content, binding)
      text_content = text_template ? render_template_content(text_template.content, binding) : nil
      
      mail(
        to: @provider.email,
        subject: html_template.subject || "Your Practice Added to Autism Services Locator (Free Service) - #{provider.name}"
      ) do |format|
        format.html { render html: html_content.html_safe }
        format.text { render plain: text_content } if text_content
      end
    else
      # Fallback to file-based templates
      mail(
        to: @provider.email,
        subject: "Your Practice Added to Autism Services Locator (Free Service) - #{provider.name}"
      )
    end
  end
  
  private
  
  def render_template_content(template_content, binding_context)
    # Use ERB to render the template content with the binding context
    ERB.new(template_content).result(binding_context)
  end
end 