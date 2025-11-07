class Api::V1::SponsorshipsController < ApplicationController
  skip_before_action :authenticate_client, only: [:tiers, :sponsored_providers]
  before_action :authenticate_user!, except: [:tiers, :sponsored_providers]
  before_action :set_sponsorship, only: [:show, :destroy]
  
  # GET /api/v1/sponsorships/tiers
  def tiers
    render json: {
      tiers: [
        {
          id: 'featured',
          name: 'Featured Provider',
          price: 25.00,
          price_in_cents: 25_00,
          price_display: '$25/Monthly',
          analytics_access: 'basic',
          analytics_description: 'Total views this month',
          features: [
            'Featured listing (appears first in search results)',
            'Enhanced visibility in provider directory',
            'Basic analytics: Total views this month'
          ],
          pricing_options: [
            {
              id: 'monthly',
              name: 'Monthly',
              price: 25.00,
              price_in_cents: 25_00,
              billing_period: 'month',
              interval: 'month'
            },
            {
              id: 'annual',
              name: '10 Months (2 Months Free)',
              price: 250.00,
              price_in_cents: 25_000,
              billing_period: 'year',
              interval: 'year',
              months_included: 12,
              months_paid: 10,
              savings: '2 months free'
            }
          ]
        },
        {
          id: 'sponsor',
          name: 'Provider Sponsor',
          price: 59.00,
          price_in_cents: 59_00,
          price_display: '$59/Monthly',
          analytics_access: 'standard',
          analytics_description: '30-day views, trend chart, clicks to website',
          features: [
            'All Featured Provider features',
            'Featured in homepage carousel',
            'Enhanced listing with badge',
            'Standard analytics: 30-day views, trend chart, clicks to website'
          ],
          pricing_options: [
            {
              id: 'monthly',
              name: 'Monthly',
              price: 59.00,
              price_in_cents: 59_00,
              billing_period: 'month',
              interval: 'month'
            },
            {
              id: 'annual',
              name: '10 Months (2 Months Free)',
              price: 590.00,
              price_in_cents: 59_000,
              billing_period: 'year',
              interval: 'year',
              months_included: 12,
              months_paid: 10,
              savings: '2 months free'
            }
          ]
        },
        {
          id: 'partner',
          name: 'Community Partner',
          price: 99.00,
          price_in_cents: 99_00,
          price_display: '$99/Monthly',
          analytics_access: 'full',
          analytics_description: 'Daily stats, 90-day history, referral sources, geographic insights',
          features: [
            'All Provider Sponsor features',
            'Top placement in all search results',
            'Priority placement in homepage carousel',
            'Premium badge display',
            'Full analytics: Daily stats, 90-day history, referral sources, geographic insights'
          ],
          pricing_options: [
            {
              id: 'monthly',
              name: 'Monthly',
              price: 99.00,
              price_in_cents: 99_00,
              billing_period: 'month',
              interval: 'month'
            },
            {
              id: 'annual',
              name: '10 Months (2 Months Free)',
              price: 990.00,
              price_in_cents: 99_000,
              billing_period: 'year',
              interval: 'year',
              months_included: 12,
              months_paid: 10,
              savings: '2 months free'
            }
          ]
        }
      ]
    }
  end
  
  # GET /api/v1/sponsorships/sponsored_providers
  def sponsored_providers
    # Get all currently sponsored providers for carousel
    sponsored = Provider.where(is_sponsored: true)
      .where('sponsored_until > ?', Time.current)
      .includes(:active_sponsorship, :locations, :practice_types)
      .order('sponsorship_tier DESC, sponsored_until DESC')
    
    render json: {
      sponsored_providers: sponsored.map do |provider|
        {
          id: provider.id,
          name: provider.name,
          tier: provider.sponsorship_tier,
          logo_url: provider.logo.attached? ? url_for(provider.logo) : nil,
          website: provider.website,
          email: provider.email,
          phone: provider.phone,
          sponsored_until: provider.sponsored_until
        }
      end
    }
  end
  
  # GET /api/v1/sponsorships
  def index
    # Get sponsorships for providers the user can manage
    managed_provider_ids = @current_user.all_managed_providers.pluck(:id)
    sponsorships = Sponsorship.where(provider_id: managed_provider_ids)
      .order(created_at: :desc)
      .includes(:provider)
    
    # Check if user has any active subscriptions
    active_sponsorships = sponsorships.select { |s| s.status == 'active' && s.ends_at && s.ends_at > Time.current }
    has_active_subscription = active_sponsorships.any?
    
    render json: {
      sponsorships: sponsorships.map do |sponsorship|
        format_sponsorship(sponsorship)
      end,
      has_active_subscription: has_active_subscription,
      message: has_active_subscription ? nil : 'No active subscriptions found. Upgrade to a sponsored tier to unlock premium features.',
      tiers_url: '/api/v1/sponsorships/tiers'
    }
  end
  
  # GET /api/v1/sponsorships/:id
  def show
    unless @current_user.can_access_provider?(@sponsorship.provider_id)
      render json: { error: 'Access denied' }, status: :forbidden
      return
    end
    
    render json: {
      sponsorship: format_sponsorship(@sponsorship)
    }
  end
  
  # DELETE /api/v1/sponsorships/:id
  def destroy
    unless @current_user.can_access_provider?(@sponsorship.provider_id)
      render json: { error: 'Access denied' }, status: :forbidden
      return
    end
    
    if @sponsorship.cancel!
      render json: {
        success: true,
        message: 'Sponsorship cancelled successfully',
        sponsorship: format_sponsorship(@sponsorship.reload)
      }
    else
      render json: { error: 'Failed to cancel sponsorship' }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_sponsorship
    @sponsorship = Sponsorship.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Sponsorship not found' }, status: :not_found
  end
  
  def format_sponsorship(sponsorship)
    {
      id: sponsorship.id,
      provider_id: sponsorship.provider_id,
      provider_name: sponsorship.provider.name,
      tier: sponsorship.tier,
      status: sponsorship.status,
      amount_paid: sponsorship.amount_paid,
      starts_at: sponsorship.starts_at,
      ends_at: sponsorship.ends_at,
      cancelled_at: sponsorship.cancelled_at,
      stripe_payment_intent_id: sponsorship.stripe_payment_intent_id,
      stripe_subscription_id: sponsorship.stripe_subscription_id,
      created_at: sponsorship.created_at,
      updated_at: sponsorship.updated_at
    }
  end
end

