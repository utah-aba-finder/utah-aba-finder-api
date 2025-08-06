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
end
