class ProviderAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :provider
  
  validates :user_id, uniqueness: { scope: :provider_id }
  validates :assigned_by, presence: true
  
  # Audit trail
  after_create :log_assignment
  after_destroy :log_unassignment
  
  private
  
  def log_assignment
    Rails.logger.info "Provider Assignment: User #{user.email} assigned to Provider #{provider.name}"
  end
  
  def log_unassignment
    Rails.logger.info "Provider Assignment: User #{user.email} unassigned from Provider #{provider.name}"
  end
end
