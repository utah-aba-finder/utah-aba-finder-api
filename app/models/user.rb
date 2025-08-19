class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Legacy relationship (for backward compatibility - PRIMARY OWNER)
  belongs_to :provider, optional: true
  
  # New multi-provider relationships via join table
  has_many :provider_assignments, dependent: :destroy
  has_many :assigned_providers, through: :provider_assignments, source: :provider
  
  # Active provider context (separate from legacy ownership)
  belongs_to :active_provider, class_name: 'Provider', optional: true
  
  # Helper method to get all providers this user can manage
  def all_managed_providers
    # Get providers where user is primary owner OR has assignments
    Provider
      .left_outer_joins(:provider_assignments)
      .where("providers.user_id = :uid OR provider_assignments.user_id = :uid", uid: id)
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
end
