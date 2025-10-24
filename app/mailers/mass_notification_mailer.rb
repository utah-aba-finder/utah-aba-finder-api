class MassNotificationMailer < ApplicationMailer
  def password_update_reminder(provider)
    @provider = provider
    @user = User.find_by(provider_id: provider.id)
    
    # Get template from database
    html_template = EmailTemplate.find_by(name: 'password_update_reminder', template_type: 'html')
    text_template = EmailTemplate.find_by(name: 'password_update_reminder', template_type: 'text')
    
    # Use database template if available, otherwise fall back to file-based
    if html_template
      # Render the database template content
      html_content = render_template_content(html_template.content, binding)
      text_content = text_template ? render_template_content(text_template.content, binding) : nil
      
      mail(
        to: @provider.email,
        subject: html_template.subject || "Important: Update Your Autism Services Locator Account - #{provider.name}"
      ) do |format|
        format.html { render html: html_content.html_safe }
        format.text { render plain: text_content } if text_content
      end
    else
      # Fallback to file-based templates
      mail(
        to: @provider.email,
        subject: "Important: Update Your Autism Services Locator Account - #{provider.name}"
      )
    end
  end

  def system_update_notification(provider)
    @provider = provider
    
    # Get template from database
    html_template = EmailTemplate.find_by(name: 'system_update', template_type: 'html')
    text_template = EmailTemplate.find_by(name: 'system_update', template_type: 'text')
    
    # Use database template if available, otherwise fall back to file-based
    if html_template
      # Render the database template content
      html_content = render_template_content(html_template.content, binding)
      text_content = text_template ? render_template_content(text_template.content, binding) : nil
      
      mail(
        to: @provider.email,
        subject: html_template.subject || "Welcome to the New Autism Services Locator System - #{provider.name}"
      ) do |format|
        format.html { render html: html_content.html_safe }
        format.text { render plain: text_content } if text_content
      end
    else
      # Fallback to file-based templates
      mail(
        to: @provider.email,
        subject: "Welcome to the New Autism Services Locator System - #{provider.name}"
      )
    end
  end
  
  private
  
  def render_template_content(template_content, binding_context)
    # Use ERB to render the template content with the binding context
    ERB.new(template_content).result(binding_context)
  end
end
