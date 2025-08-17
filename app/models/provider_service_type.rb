class ProviderServiceType < ApplicationRecord
  belongs_to :provider
  belongs_to :provider_category
  
  validates :provider_id, uniqueness: { scope: :provider_category_id, message: "already has this service type" }
  validate :only_one_primary_per_provider
  
  scope :primary, -> { where(is_primary: true) }
  scope :secondary, -> { where(is_primary: false) }
  
  private
  
  def only_one_primary_per_provider
    if is_primary? && provider.provider_service_types.where(is_primary: true).where.not(id: id).exists?
      errors.add(:is_primary, "only one primary service type allowed per provider")
    end
  end
end 