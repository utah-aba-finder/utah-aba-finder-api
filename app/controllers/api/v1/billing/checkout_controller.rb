class Api::V1::Billing::CheckoutController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider

  def create
    plan = params[:plan] # "featured" | "sponsor" | "partner"
    billing_period = params[:billing_period] || 'month' # "month" | "year" (for 10-month plan)
    
    unless %w[featured sponsor partner].include?(plan)
      render json: { error: "Unknown plan. Must be one of: featured, sponsor, partner" }, status: :unprocessable_entity
      return
    end

    unless %w[month year].include?(billing_period)
      render json: { error: "Unknown billing period. Must be one of: month, year" }, status: :unprocessable_entity
      return
    end

    # Determine which price ID to use based on plan and billing period
    price_id = if billing_period == 'year'
      # 10-month plan (annual)
      case plan
      when "featured" then ENV.fetch("STRIPE_PRICE_FEATURED_ANNUAL", nil)
      when "sponsor"  then ENV.fetch("STRIPE_PRICE_SPONSOR_ANNUAL", nil)
      when "partner"  then ENV.fetch("STRIPE_PRICE_PARTNER_ANNUAL", nil)
      end
    else
      # Monthly plan
      case plan
      when "featured" then ENV.fetch("STRIPE_PRICE_FEATURED", nil)
      when "sponsor"  then ENV.fetch("STRIPE_PRICE_SPONSOR", nil)
      when "partner"  then ENV.fetch("STRIPE_PRICE_PARTNER", nil)
      end
    end

    unless price_id.present?
      env_var_name = billing_period == 'year' ? 
        "STRIPE_PRICE_#{plan.upcase}_ANNUAL" : 
        "STRIPE_PRICE_#{plan.upcase}"
      render json: { 
        error: "Price ID not configured for plan: #{plan} (#{billing_period})",
        env_var: env_var_name
      }, status: :unprocessable_entity
      return
    end

    begin
      # Ensure provider has a Stripe customer ID
      customer = get_or_create_stripe_customer

      # Create Stripe Checkout Session
      session = Stripe::Checkout::Session.create(
        mode: "subscription",
        customer: customer.id,
        line_items: [{ price: price_id, quantity: 1 }],
        success_url: "#{ENV.fetch('APP_URL', 'https://www.autismserviceslocator.com')}/providers/dashboard?upgrade=success",
        cancel_url: "#{ENV.fetch('APP_URL', 'https://www.autismserviceslocator.com')}/providers/sponsor?canceled=1",
        metadata: {
          provider_id: @provider.id,
          plan: plan,
          billing_period: billing_period
        }
      )

      render json: { url: session.url }
    rescue KeyError => e
      Rails.logger.error "Missing environment variable: #{e.message}"
      render json: { error: "Configuration error: #{e.message}" }, status: :internal_server_error
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error: #{e.message}"
      render json: { error: "Payment processing error: #{e.message}" }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Checkout session creation failed: #{e.message}"
      render json: { error: "Failed to create checkout session" }, status: :internal_server_error
    end
  end

  private

  def set_provider
    provider_id = params[:provider_id] || @current_user.active_provider&.id
    
    unless provider_id
      render json: { error: 'Provider ID is required. Either pass provider_id or set an active provider.' }, status: :bad_request
      return
    end

    @provider = Provider.find(provider_id)
    
    unless @current_user.can_access_provider?(@provider.id)
      render json: { error: 'Access denied. You can only purchase sponsorship for providers you manage.' }, status: :forbidden
      return
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Provider not found' }, status: :not_found
  end

  def get_or_create_stripe_customer
    # Check if provider already has a Stripe customer ID
    if @provider.stripe_customer_id.present?
      begin
        customer = Stripe::Customer.retrieve(@provider.stripe_customer_id)
        return customer if customer.present?
      rescue Stripe::StripeError
        # Customer doesn't exist, create a new one
      end
    end

    # Create new Stripe customer
    customer = Stripe::Customer.create(
      email: @provider.email || @current_user.email,
      name: @provider.name,
      metadata: {
        provider_id: @provider.id,
        user_id: @current_user.id
      }
    )
    
    @provider.update(stripe_customer_id: customer.id)
    customer
  end
end

