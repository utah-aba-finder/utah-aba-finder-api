class Api::V1::Admin::MassEmailsController < Api::V1::Admin::BaseController
  def index
    # Get statistics about users and providers
    users_with_providers = User.where.not(provider_id: nil)
    old_users = users_with_providers.where("created_at < ?", 1.week.ago)
    recent_users = users_with_providers.where("created_at >= ?", 1.week.ago)
    
    # Get provider details for users needing updates
    provider_ids = old_users.pluck(:provider_id)
    providers_needing_updates = Provider.where(id: provider_ids, status: :approved)
    
    render json: {
      statistics: {
        total_users_with_providers: users_with_providers.count,
        users_needing_password_updates: old_users.count,
        recently_updated_users: recent_users.count,
        providers_needing_updates: providers_needing_updates.count
      },
      providers_needing_updates: providers_needing_updates.map do |provider|
        user = User.find_by(provider_id: provider.id)
        {
          id: provider.id,
          name: provider.name,
          email: provider.email,
          user_email: user&.email,
          created_at: provider.created_at,
          user_created_at: user&.created_at
        }
      end
    }
  end

  def send_password_reminders
    # Get users who need password updates
    users_with_providers = User.where.not(provider_id: nil)
    old_users = users_with_providers.where("created_at < ?", 1.week.ago)
    provider_ids = old_users.pluck(:provider_id)
    providers_needing_updates = Provider.where(id: provider_ids, status: :approved)
    
    sent_count = 0
    error_count = 0
    errors = []
    
    providers_needing_updates.find_in_batches(batch_size: 10) do |batch|
      batch.each do |provider|
        begin
          user = User.find_by(provider_id: provider.id)
          if user
            MassNotificationMailer.password_update_reminder(provider).deliver_now
            sent_count += 1
          else
            errors << "No user found for provider: #{provider.name}"
          end
        rescue => e
          error_count += 1
          errors << "Failed to send to #{provider.name}: #{e.message}"
        end
      end
      
      # Small delay between batches
      sleep(1)
    end
    
    render json: {
      success: true,
      message: "Password reminder emails sent",
      statistics: {
        total_providers: providers_needing_updates.count,
        emails_sent: sent_count,
        errors: error_count
      },
      errors: errors
    }
  end

  def send_system_updates
    # Get all approved providers
    providers = Provider.where(status: :approved)
    
    sent_count = 0
    error_count = 0
    errors = []
    
    providers.find_in_batches(batch_size: 10) do |batch|
      batch.each do |provider|
        begin
          MassNotificationMailer.system_update_notification(provider).deliver_now
          sent_count += 1
        rescue => e
          error_count += 1
          errors << "Failed to send to #{provider.name}: #{e.message}"
        end
      end
      
      # Small delay between batches
      sleep(1)
    end
    
    render json: {
      success: true,
      message: "System update emails sent",
      statistics: {
        total_providers: providers.count,
        emails_sent: sent_count,
        errors: error_count
      },
      errors: errors
    }
  end

  def preview_email
    provider = Provider.find(params[:provider_id])
    user = User.find_by(provider_id: provider.id)
    
    if user
      # Generate the email content without sending
      mail = MassNotificationMailer.password_update_reminder(provider)
      render json: {
        success: true,
        subject: mail.subject,
        to: mail.to,
        html_content: mail.body.to_s,
        text_content: mail.text_part&.body&.to_s
      }
    else
      render json: { success: false, error: "No user found for this provider" }
    end
  end
end
