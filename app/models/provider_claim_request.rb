class ProviderClaimRequest < ApplicationRecord
  belongs_to :provider
  belongs_to :reviewed_by, class_name: 'User', optional: true
  
  validates :claimer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: %w[pending approved rejected] }
  
  scope :pending, -> { where(status: 'pending', is_processed: false) }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  
  def can_be_approved?
    status == 'pending' && !is_processed
  end
  
  def can_be_rejected?
    status == 'pending' && !is_processed
  end
  
  def approve!(admin_user, notes = nil)
    return false unless can_be_approved?
    
    reload
    return false unless can_be_approved?
    
    begin
      # Create or link user account
      user = User.find_by(email: claimer_email.downcase)
      
      if user.nil?
        # Create new user account
        password = SecureRandom.alphanumeric(12)
        user = User.new(
          email: claimer_email.downcase,
          password: password,
          password_confirmation: password,
          role: 'user'
        )
        
        unless user.save
          errors.add(:base, "Failed to create user account: #{user.errors.full_messages.join(', ')}")
          return false
        end
        
        # Store password temporarily for email
        user.instance_variable_set(:@plain_password, password)
      end
      
      # Link user to provider
      if user.provider_id.nil?
        user.update!(provider_id: provider.id)
      end
      
      # Create provider assignment
      ProviderAssignment.find_or_create_by(
        user: user,
        provider: provider
      ) do |a|
        a.assigned_by = admin_user.email
      end
      
      # Update claim request status
      update_columns(
        status: 'approved',
        reviewed_at: Time.current,
        reviewed_by_id: admin_user.id,
        admin_notes: notes,
        is_processed: true
      )
      
      reload
      
      # Send welcome email with credentials to the claimer (not the provider's registered email)
      if user.instance_variable_get(:@plain_password)
        # Send approval email with credentials to the claimer
        ProviderClaimMailer.claim_approved(self, user).deliver_later
      else
        # User already exists, just send notification
        ProviderClaimMailer.claim_approved(self, user).deliver_later
      end
      
      true
    rescue => e
      Rails.logger.error "Error approving claim request: #{e.message}"
      errors.add(:base, "Failed to approve claim: #{e.message}")
      false
    end
  end
  
  def reject!(admin_user, reason = nil, notes = nil)
    return false unless can_be_rejected?
    
    update_columns(
      status: 'rejected',
      reviewed_at: Time.current,
      reviewed_by_id: admin_user.id,
      rejection_reason: reason,
      admin_notes: notes,
      is_processed: true
    )
    
    reload
    
    # Send rejection email
    ProviderClaimMailer.claim_rejected(self).deliver_later
    
    true
  end
end
