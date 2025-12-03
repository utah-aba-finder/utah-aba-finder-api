class Sponsorship < ApplicationRecord
  belongs_to :provider
  
  # Tier pricing (in cents for Stripe)
  TIER_PRICING = {
    'basic' => 99_00,      # $99/month - Featured listing
    'premium' => 199_00,   # $199/month - Featured listing + carousel
    'featured' => 299_00   # $299/month - Featured listing + carousel + top placement
  }.freeze
  
  # Status transitions
  enum status: {
    pending: 'pending',
    active: 'active',
    cancelled: 'cancelled',
    expired: 'expired'
  }, _prefix: :status
  
  validates :tier, inclusion: { in: TIER_PRICING.keys }
  validates :provider_id, presence: true
  
  scope :active_sponsorships, -> { where(status: 'active').where('ends_at > ?', Time.current) }
  scope :current, -> { where('starts_at <= ? AND ends_at >= ?', Time.current, Time.current) }
  
  # Calculate end date based on tier and payment
  def calculate_end_date
    return nil unless starts_at
    
    case tier
    when 'basic'
      starts_at + 1.month
    when 'premium'
      starts_at + 1.month
    when 'featured'
      starts_at + 1.month
    else
      starts_at + 1.month
    end
  end
  
  # Activate sponsorship
  def activate!
    return false if status_active?
    
    update!(
      status: 'active',
      starts_at: Time.current,
      ends_at: calculate_end_date
    )
    
    # Map tier string to integer enum value
    tier_enum_value = case tier.to_s.downcase
                     when 'featured'
                       1 # featured
                     when 'sponsor'
                       2 # sponsor
                     when 'partner'
                       3 # partner
                     else
                       0 # free
                     end
    
    # Update provider with integer enum value
    provider.update!(
      is_sponsored: true,
      sponsored_until: ends_at,
      sponsorship_tier: tier_enum_value,
      stripe_customer_id: stripe_customer_id,
      stripe_subscription_id: stripe_subscription_id
    )
    
    true
  end
  
  # Cancel sponsorship
  def cancel!
    return false if status_cancelled? || expired?
    
    update!(
      status: 'cancelled',
      cancelled_at: Time.current
    )
    
    # Update provider if this is the active sponsorship
    # Compare tier string to provider's enum value
    tier_enum_value = case tier.to_s.downcase
                     when 'featured'
                       1
                     when 'sponsor'
                       2
                     when 'partner'
                       3
                     else
                       0
                     end
    
    if provider.sponsorship_tier_before_type_cast == tier_enum_value && provider.is_sponsored?
      provider.update!(
        is_sponsored: false,
        sponsored_until: nil,
        sponsorship_tier: 0 # free
      )
    end
    
    true
  end
  
  # Check if sponsorship is expired
  def expired?
    ends_at.present? && ends_at < Time.current && status != 'expired'
  end
  
  # Get price in dollars
  def price_in_dollars
    TIER_PRICING[tier] / 100.0
  end
end

