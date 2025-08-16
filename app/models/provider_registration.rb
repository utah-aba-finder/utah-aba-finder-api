class ProviderRegistration < ApplicationRecord
  belongs_to :reviewed_by, class_name: 'User', optional: true
  
  # Ensure JSONB fields are properly typed
  attribute :submitted_data, :json, default: {}
  attribute :metadata, :json, default: {}
  
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :provider_name, presence: true
  validates :category, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :unprocessed, -> { where(is_processed: false) }
  scope :recent, -> { order(created_at: :desc) }
  
  before_validation :set_default_status
  
  def pending?
    status == 'pending'
  end
  
  def approved?
    status == 'approved'
  end
  
  def rejected?
    status == 'rejected'
  end
  
  def can_be_approved?
    pending? && !is_processed
  end
  
  def can_be_rejected?
    pending? && !is_processed
  end
  
  def approve!(admin_user, notes = nil)
    return false unless can_be_approved?
    
    update!(
      status: 'approved',
      reviewed_by: admin_user,
      reviewed_at: Time.current,
      admin_notes: notes,
      is_processed: true
    )
    
    # Send approval email to provider
    ProviderRegistrationMailer.approved(self).deliver_later
  end
  
  def reject!(admin_user, reason, notes = nil)
    return false unless can_be_rejected?
    
    update!(
      status: 'rejected',
      reviewed_by: admin_user,
      reviewed_at: Time.current,
      rejection_reason: reason,
      admin_notes: notes,
      is_processed: true
    )
    
    # Send rejection email to provider
    ProviderRegistrationMailer.rejected(self).deliver_later
  end
  
  def category_display_name
    category.titleize
  end
  
  def submitted_data_summary
    submitted_data.except('email', 'provider_name', 'category').map do |key, value|
      "#{key.titleize}: #{value}"
    end.join(', ')
  end
  
  private
  
  def set_default_status
    self.status = 'pending' if status.blank?
  end
end 