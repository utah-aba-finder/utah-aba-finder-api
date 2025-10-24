class EmailTemplate < ApplicationRecord
  validates :name, presence: true, uniqueness: { scope: :template_type }
  validates :content, presence: true
  validates :template_type, presence: true, inclusion: { in: %w[html text] }
  
  scope :html_templates, -> { where(template_type: 'html') }
  scope :text_templates, -> { where(template_type: 'text') }
  
  def self.find_or_initialize_by_name_and_type(name, template_type = 'html')
    find_or_initialize_by(name: name, template_type: template_type)
  end
  
  def self.seed_default_templates
    templates = [
      {
        name: 'password_update_reminder',
        template_type: 'html',
        description: 'Sent to users who need to update their passwords',
        subject: 'Important: Action Required for Your Autism Services Locator Account',
        content: File.read(Rails.root.join('app/views/mass_notification_mailer/password_update_reminder.html.erb'))
      },
      {
        name: 'password_update_reminder',
        template_type: 'text',
        description: 'Sent to users who need to update their passwords',
        subject: 'Important: Action Required for Your Autism Services Locator Account',
        content: File.read(Rails.root.join('app/views/mass_notification_mailer/password_update_reminder.text.erb'))
      },
      {
        name: 'admin_created_provider',
        template_type: 'html',
        description: 'Sent when you manually add a provider to the platform',
        subject: 'Your Practice Added to Autism Services Locator (Free Service)',
        content: File.read(Rails.root.join('app/views/provider_registration_mailer/admin_created_provider.html.erb'))
      },
      {
        name: 'admin_created_provider',
        template_type: 'text',
        description: 'Sent when you manually add a provider to the platform',
        subject: 'Your Practice Added to Autism Services Locator (Free Service)',
        content: File.read(Rails.root.join('app/views/provider_registration_mailer/admin_created_provider.text.erb'))
      },
      {
        name: 'system_update',
        template_type: 'html',
        description: 'General system updates and announcements',
        subject: 'System Update from Autism Services Locator',
        content: File.read(Rails.root.join('app/views/mass_notification_mailer/system_update_notification.html.erb'))
      },
      {
        name: 'system_update',
        template_type: 'text',
        description: 'General system updates and announcements',
        subject: 'System Update from Autism Services Locator',
        content: File.read(Rails.root.join('app/views/mass_notification_mailer/system_update_notification.text.erb'))
      }
    ]
    
    templates.each do |template_data|
      template = find_or_initialize_by(name: template_data[:name], template_type: template_data[:template_type])
      template.assign_attributes(template_data.except(:name, :template_type))
      template.save!
    end
  end
end
