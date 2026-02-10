class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Notify admin when password is changed (via any method: change_password, reset_password, etc.)
  after_update :notify_admin_if_password_changed, if: :saved_change_to_encrypted_password?

  # Legacy relationship (for backward compatibility - PRIMARY OWNER)
  belongs_to :provider, optional: true
  
  # New multi-provider relationships via join table
  has_many :provider_assignments, dependent: :destroy
  has_many :assigned_providers, through: :provider_assignments, source: :provider
  
  # Active provider context (separate from legacy ownership)
  belongs_to :active_provider, class_name: 'Provider', optional: true
  
  # Helper method to get all providers this user can manage
  def all_managed_providers
    # Get providers where user is primary owner OR has assignments OR has legacy provider_id
    Provider
      .left_outer_joins(:provider_assignments)
      .where("providers.user_id = :uid OR provider_assignments.user_id = :uid OR providers.id = :legacy_provider_id", 
             uid: id, legacy_provider_id: provider_id)
      .distinct
      .includes(:locations, :practice_types, :insurances, :counties)
  end

  # Alias for backward compatibility with existing code
  def managed_providers
    all_managed_providers
  end

  # Method to set the current active provider context
  def set_active_provider(provider_id)
    target_provider = all_managed_providers.find { |p| p.id == provider_id.to_i }
    return false unless target_provider
    
    # Update the active provider context (NOT the legacy ownership)
    update!(active_provider_id: target_provider.id)
    true
  end

  # Method to get the currently active provider context
  def active_provider
    active_provider_id ? Provider.find(active_provider_id) : provider
  end

  # Method to check if user can access a specific provider
  def can_access_provider?(provider_id)
    # Super admins can access any provider
    return true if role == 'super_admin' || role.to_s == '0'
    
    # Regular users can only access providers they manage
    all_managed_providers.where(id: provider_id.to_i).exists?
  end
  
  # Check if user is primary owner of a provider
  def primary_owner_of?(provider)
    provider.user_id == id
  end
  
  # Check if user has assigned access to a provider
  def assigned_to?(provider)
    provider_assignments.exists?(provider: provider)
  end
  
  private
  
  def notify_admin_if_password_changed
    # Skip notification if this is a new user (password being set for first time)
    # saved_change_to_encrypted_password? returns [old_value, new_value] or nil
    change = saved_change_to_encrypted_password
    return if change.nil? || change[0].blank? # Skip if no old password (new user)
    
    # Send admin notification about password change
    begin
      AdminNotificationMailer.password_changed(self).deliver_now
      Rails.logger.info "Admin notification sent for password change: User #{id} (#{email})"
    rescue => email_error
      Rails.logger.error "⚠️ Failed to send admin notification for password change: #{email_error.message}"
      # Continue - password change succeeded even if email fails
    end
  end
end
