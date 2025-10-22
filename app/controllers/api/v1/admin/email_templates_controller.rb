class Api::V1::Admin::EmailTemplatesController < Api::V1::Admin::BaseController
  def index
    templates = {
      password_update_reminder: {
        name: "Password Update Reminder",
        description: "Sent to users who need to update their passwords",
        subject: "Important: Action Required for Your Autism Services Locator Account",
        html_file: "password_update_reminder.html.erb",
        text_file: "password_update_reminder.text.erb"
      },
      admin_created_provider: {
        name: "Admin Created Provider Welcome",
        description: "Sent when you manually add a provider to the platform",
        subject: "Your Practice Added to Autism Services Locator (Free Service)",
        html_file: "admin_created_provider.html.erb",
        text_file: "admin_created_provider.text.erb"
      },
      system_update: {
        name: "System Update Notification",
        description: "General system updates and announcements",
        subject: "Important Updates from Autism Services Locator",
        html_file: "system_update_notification.html.erb",
        text_file: "system_update_notification.text.erb"
      }
    }
    
    render json: { templates: templates }
  end

  def show
    template_name = params[:id]
    template_type = params[:type] || 'html'
    
    # Determine the correct file path based on template name
    if template_name.include?('admin_created_provider')
      template_path = "app/views/provider_registration_mailer/#{template_name}.#{template_type}.erb"
    else
      # Handle naming mismatch for system_update -> system_update_notification
      actual_template_name = template_name == 'system_update' ? 'system_update_notification' : template_name
      template_path = "app/views/mass_notification_mailer/#{actual_template_name}.#{template_type}.erb"
    end
    
    if File.exist?(template_path)
      content = File.read(template_path)
      render json: { 
        template_name: template_name,
        content: content,
        type: template_type
      }
    else
      render json: { error: "Template not found at path: #{template_path}" }, status: :not_found
    end
  end

  def update
    template_name = params[:id]
    template_type = params[:type] || 'html'
    
    # Determine the correct file path
    if template_name.include?('admin_created_provider')
      file_path = "app/views/provider_registration_mailer/#{template_name}.#{template_type}.erb"
    else
      # Handle naming mismatch for system_update -> system_update_notification
      actual_template_name = template_name == 'system_update' ? 'system_update_notification' : template_name
      file_path = "app/views/mass_notification_mailer/#{actual_template_name}.#{template_type}.erb"
    end
    
    begin
      # Write the new content to the file
      File.write(file_path, params[:content])
      
      # If this is a production environment, we might want to reload the templates
      # In development, Rails will auto-reload
      
      render json: { 
        success: true, 
        message: "Template updated successfully",
        template_name: template_name,
        type: template_type
      }
    rescue => e
      render json: { 
        success: false, 
        error: "Failed to update template: #{e.message}" 
      }, status: :unprocessable_entity
    end
  end

  def preview
    template_name = params[:id]
    template_type = params[:type] || 'html'
    
    # Create a mock provider and user for preview
    mock_provider = OpenStruct.new(
      name: "Sample Practice Name",
      email: "sample@practice.com"
    )
    
    mock_user = OpenStruct.new(
      email: "sample@practice.com"
    )
    
    begin
      if template_name.include?('admin_created_provider')
        # For admin created provider, we need to set the password on the user
        mock_user.instance_variable_set(:@plain_password, "SamplePassword123")
        mail = ProviderRegistrationMailer.admin_created_provider(mock_provider, mock_user)
      else
        # For mass notification emails
        case template_name
        when 'password_update_reminder'
          mail = MassNotificationMailer.password_update_reminder(mock_provider)
        when 'system_update'
          mail = MassNotificationMailer.system_update_notification(mock_provider)
        else
          raise "Unknown template: #{template_name}"
        end
      end
      
      render json: {
        success: true,
        subject: mail.subject,
        to: mail.to,
        html_content: mail.body.to_s,
        text_content: mail.text_part&.body&.to_s
      }
    rescue => e
      render json: { 
        success: false, 
        error: "Failed to preview template: #{e.message}" 
      }, status: :unprocessable_entity
    end
  end

  def reset
    template_name = params[:id]
    template_type = params[:type] || 'html'
    
    # This would reset to a default template
    # For now, we'll just return an error since we don't have backup templates
    render json: { 
      success: false, 
      error: "Reset functionality not implemented yet" 
    }, status: :not_implemented
  end
end
