class Api::V1::Admin::EmailTemplatesController < Api::V1::Admin::BaseController
  def index
    # Seed default templates if they don't exist
    EmailTemplate.seed_default_templates if EmailTemplate.count == 0
    
    # Group templates by name for easier frontend consumption
    templates = {}
    EmailTemplate.all.group_by(&:name).each do |name, template_records|
      html_template = template_records.find { |t| t.template_type == 'html' }
      text_template = template_records.find { |t| t.template_type == 'text' }
      
      templates[name] = {
        name: html_template&.name || text_template&.name,
        description: html_template&.description || text_template&.description,
        subject: html_template&.subject || text_template&.subject,
        html_file: html_template ? "#{name}.html.erb" : nil,
        text_file: text_template ? "#{name}.text.erb" : nil
      }
    end
    
    render json: { templates: templates }
  end

  def show
    template_name = params[:id]
    template_type = params[:type] || 'html'
    
    # Find template in database
    template = EmailTemplate.find_by(name: template_name, template_type: template_type)
    
    if template
      render json: { 
        template_name: template.name,
        content: template.content,
        type: template.template_type
      }
    else
      render json: { error: "Template not found: #{template_name} (#{template_type})" }, status: :not_found
    end
  end

  def update
    template_name = params[:id]
    template_type = params[:type] || 'html'
    
    begin
      # Find or create template in database
      template = EmailTemplate.find_or_initialize_by(name: template_name, template_type: template_type)
      
      # Log the update attempt
      Rails.logger.info "📝 Updating template: #{template_name} (#{template_type})"
      Rails.logger.info "📝 Content length: #{params[:content]&.length || 0} characters"
      
      # Update the template content
      template.content = params[:content]
      template.save!
      
      Rails.logger.info "✅ Template updated successfully in database"
      
      render json: { 
        success: true, 
        message: "Template updated successfully",
        template_name: template.name,
        type: template.template_type,
        content_length: template.content.length
      }
    rescue => e
      Rails.logger.error "❌ Failed to update template: #{e.message}"
      Rails.logger.error "❌ Backtrace: #{e.backtrace.first(5).join('\n')}"
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
