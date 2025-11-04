class Api::V1::Admin::MassEmailsController < Api::V1::Admin::BaseController
  def index
    # Get statistics about users and providers
    # Include users who are primary owners (via Provider.user_id) or have legacy provider_id
    users_with_providers = User.where(
      "id IN (SELECT DISTINCT user_id FROM providers WHERE user_id IS NOT NULL) OR provider_id IS NOT NULL"
    )
    old_users = users_with_providers.where("created_at < ?", 1.week.ago)
    
    # Track users who recently reset their password (within the last week)
    recently_reset_password = users_with_providers
      .where("reset_password_sent_at >= ?", 1.week.ago)
      .where.not(reset_password_sent_at: nil)
    
    # Get providers for users who recently reset their password
    recently_reset_provider_ids = Provider.where(user_id: recently_reset_password.pluck(:id)).pluck(:id)
    legacy_recently_reset_provider_ids = recently_reset_password.where.not(provider_id: nil).pluck(:provider_id).compact
    all_recently_reset_provider_ids = (recently_reset_provider_ids + legacy_recently_reset_provider_ids).uniq
    
    # Also include providers where the user was recently updated (happens when password reset is completed)
    recently_updated_users = users_with_providers.where("updated_at >= ?", 1.week.ago)
    recently_updated_user_provider_ids = Provider.where(user_id: recently_updated_users.pluck(:id)).pluck(:id)
    legacy_recently_updated_user_provider_ids = recently_updated_users.where.not(provider_id: nil).pluck(:provider_id).compact
    all_recently_updated_user_provider_ids = (recently_updated_user_provider_ids + legacy_recently_updated_user_provider_ids).uniq
    
    # Also include providers that were recently updated themselves (indicating they logged in and updated info)
    # BUT only if they have user accounts (can't reset password without a user account)
    recently_updated_provider_ids = Provider.where(status: :approved)
      .where("updated_at >= ?", 1.week.ago)
      .where(
        "user_id IN (SELECT id FROM users) OR " \
        "id IN (SELECT DISTINCT provider_id FROM provider_assignments) OR " \
        "id IN (SELECT DISTINCT provider_id FROM users WHERE provider_id IS NOT NULL) OR " \
        "email IN (SELECT email FROM users)"
      )
      .pluck(:id)
    
    # Combine all: providers with recent password resets OR recent user updates OR recent provider updates
    all_recently_updated_provider_ids = (
      all_recently_reset_provider_ids + 
      all_recently_updated_user_provider_ids + 
      recently_updated_provider_ids
    ).uniq
    recently_updated_providers = Provider.where(id: all_recently_updated_provider_ids, status: :approved)
    
    # Get provider details for users needing updates
    # Get providers where user is primary owner (via Provider.user_id) or legacy provider_id
    # EXCLUDE providers that are already recently updated
    old_provider_ids = Provider.where(user_id: old_users.pluck(:id)).pluck(:id)
    legacy_provider_ids = old_users.where.not(provider_id: nil).pluck(:provider_id).compact
    all_provider_ids = (old_provider_ids + legacy_provider_ids).uniq
    # Exclude recently updated providers from needing updates
    providers_needing_updates_ids = all_provider_ids - all_recently_updated_provider_ids
    providers_needing_updates = Provider.where(id: providers_needing_updates_ids, status: :approved)
    
    render json: {
      statistics: {
        total_users_with_providers: users_with_providers.count,
        users_needing_password_updates: old_users.count,
        recently_reset_password_count: recently_reset_password.count,
        providers_needing_updates: providers_needing_updates.count,
        recently_updated_providers_count: recently_updated_providers.count
      },
      providers_needing_updates: providers_needing_updates.map do |provider|
        # Find primary owner via Provider.user_id (primary owner relationship)
        user = provider.user
        {
          id: provider.id,
          name: provider.name,
          email: provider.email,
          user_email: user&.email,
          created_at: provider.created_at,
          updated_at: provider.updated_at,
          user_created_at: user&.created_at,
          reset_password_sent_at: user&.reset_password_sent_at
        }
      end,
      recently_updated_providers: recently_updated_providers.map do |provider|
        # Find primary owner via Provider.user_id (primary owner relationship)
        user = provider.user
        {
          id: provider.id,
          name: provider.name,
          email: provider.email,
          user_email: user&.email,
          created_at: provider.created_at,
          updated_at: provider.updated_at,
          user_created_at: user&.created_at,
          reset_password_sent_at: user&.reset_password_sent_at
        }
      end
    }
  end

  def send_password_reminders
    # Get users who need password updates
    # Include users who are primary owners (via Provider.user_id) or have legacy provider_id
    users_with_providers = User.where(
      "id IN (SELECT DISTINCT user_id FROM providers WHERE user_id IS NOT NULL) OR provider_id IS NOT NULL"
    )
    old_users = users_with_providers.where("created_at < ?", 1.week.ago)
    
    # Get providers where user is primary owner (via Provider.user_id) or legacy provider_id
    old_provider_ids = Provider.where(user_id: old_users.pluck(:id)).pluck(:id)
    legacy_provider_ids = old_users.where.not(provider_id: nil).pluck(:provider_id).compact
    all_provider_ids = (old_provider_ids + legacy_provider_ids).uniq
    providers_needing_updates = Provider.where(id: all_provider_ids, status: :approved)
    
    sent_count = 0
    error_count = 0
    errors = []
    
    providers_needing_updates.find_in_batches(batch_size: 10) do |batch|
      batch.each do |provider|
        begin
          # Find primary owner via Provider.user_id (primary owner relationship)
          user = provider.user
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
    # Find primary owner via Provider.user_id (primary owner relationship)
    user = provider.user
    
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
