class Api::V1::SponsorshipsController < ApplicationController
  before_action :authenticate_user!
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
          features: [
            'Featured listing (appears first in search results)',
            'Enhanced visibility in provider directory'
          ]
        },
        {
          id: 'sponsor',
          name: 'Provider Sponsor',
          price: 54.00,
          price_in_cents: 54_00,
          features: [
            'All Featured Provider features',
            'Featured in homepage carousel',
            'Enhanced listing with badge'
          ]
        },
        {
          id: 'partner',
          name: 'Community Sponsor',
          price: 99.00,
          price_in_cents: 99_00,
          features: [
            'All Provider Sponsor features',
            'Top placement in all search results',
            'Priority placement in homepage carousel',
            'Premium badge display',
            'View statistics dashboard'
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
    
    render json: {
      sponsorships: sponsorships.map do |sponsorship|
        format_sponsorship(sponsorship)
      end
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

