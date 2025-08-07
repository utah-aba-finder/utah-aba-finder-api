class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Legacy relationship (for backward compatibility)
  belongs_to :provider, optional: true
  
  # New relationship for managing multiple providers
  has_many :managed_providers, class_name: 'Provider', foreign_key: 'user_id'
  
  # Helper method to get all providers this user can manage
  def all_managed_providers
    providers = []
    providers << provider if provider.present?
    providers += managed_providers
    providers.uniq
  end

  # Method to set the current active provider context
  def set_active_provider(provider_id)
    target_provider = all_managed_providers.find { |p| p.id == provider_id.to_i }
    return false unless target_provider
    
    # Update the legacy relationship to set the active provider
    update!(provider_id: target_provider.id)
    true
  end

  # Method to get the currently active provider
  def active_provider
    provider
  end

  # Method to check if user can access a specific provider
  def can_access_provider?(provider_id)
    all_managed_providers.any? { |p| p.id == provider_id.to_i }
  end
end
