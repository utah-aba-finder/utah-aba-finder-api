class Api::V1::StripeWebhooksController < ApplicationController
  skip_before_action :authenticate_client
  
  # Stripe webhook endpoint
  def handle
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.configuration.stripe[:webhook_secret]
    
    # Set Stripe API key for webhook processing
    Stripe.api_key ||= Rails.configuration.stripe[:secret_key]
    
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
      
      Rails.logger.info "Webhook received: #{event.type} (id: #{event.id})"
    rescue JSON::ParserError => e
      Rails.logger.error "Webhook JSON parsing error: #{e.message}"
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Webhook signature verification error: #{e.message}"
      render json: { error: 'Invalid signature' }, status: 400
      return
    end
    
    # Handle the event
    case event.type
    when 'checkout.session.completed'
      handle_checkout_session_completed(event.data.object)
    when 'payment_intent.succeeded'
      handle_payment_intent_succeeded(event.data.object)
    when 'payment_intent.payment_failed'
      handle_payment_intent_failed(event.data.object)
    when 'customer.subscription.created'
      handle_subscription_created(event.data.object)
    when 'customer.subscription.updated'
      handle_subscription_updated(event.data.object)
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event.data.object)
    when 'invoice.payment_succeeded'
      handle_invoice_payment_succeeded(event.data.object)
    when 'invoice.payment_failed'
      handle_invoice_payment_failed(event.data.object)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end
    
    render json: { received: true }, status: :ok
  end
  
  private
  
  def handle_checkout_session_completed(checkout_session)
    Rails.logger.info "Checkout session completed: #{checkout_session.id}"
    
    # Get provider from metadata
    provider_id = checkout_session.metadata['provider_id']
    plan = checkout_session.metadata['plan'] # "featured", "sponsor", or "partner"
    
    unless provider_id
      Rails.logger.warn "No provider_id in checkout session metadata: #{checkout_session.id}"
      return
    end
    
    provider = Provider.find_by(id: provider_id)
    unless provider
      Rails.logger.warn "Provider not found for checkout session: #{checkout_session.id}, provider_id: #{provider_id}"
      return
    end
    
    # Get subscription from checkout session
    subscription_id = checkout_session.subscription
    
    if subscription_id
      # Retrieve subscription to get full details
      subscription = Stripe::Subscription.retrieve(subscription_id)
      
      # Determine tier from price ID or plan metadata
      tier = determine_tier_from_price_id_or_plan(subscription, plan)
      
      # Create or update sponsorship
      sponsorship = provider.sponsorships.find_or_initialize_by(
        stripe_subscription_id: subscription_id
      )
      
      sponsorship.update!(
        tier: tier,
        stripe_customer_id: checkout_session.customer,
        status: 'active',
        starts_at: Time.at(subscription.current_period_start),
        ends_at: Time.at(subscription.current_period_end),
        amount_paid: subscription.items.data.first.price.unit_amount / 100.0
      )
      
      sponsorship.activate!
      Rails.logger.info "Checkout sponsorship activated: #{sponsorship.id} for provider #{provider.name} with tier #{tier}"
    else
      Rails.logger.warn "No subscription found in checkout session: #{checkout_session.id}"
    end
  end
  
  def handle_payment_intent_succeeded(payment_intent)
    Rails.logger.info "Payment succeeded: #{payment_intent.id}"
    
    sponsorship = Sponsorship.find_by(stripe_payment_intent_id: payment_intent.id)
    
    if sponsorship
      sponsorship.activate!
      Rails.logger.info "Sponsorship activated: #{sponsorship.id}"
    else
      Rails.logger.warn "Sponsorship not found for payment intent: #{payment_intent.id}"
    end
  end
  
  def handle_payment_intent_failed(payment_intent)
    Rails.logger.info "Payment failed: #{payment_intent.id}"
    
    sponsorship = Sponsorship.find_by(stripe_payment_intent_id: payment_intent.id)
    
    if sponsorship
      sponsorship.update(status: 'cancelled', cancelled_at: Time.current)
      Rails.logger.info "Sponsorship cancelled: #{sponsorship.id}"
    end
  end
  
  def handle_subscription_created(subscription)
    Rails.logger.info "Subscription created: #{subscription.id}"
    Rails.logger.info "Subscription customer: #{subscription.customer}"
    Rails.logger.info "Subscription metadata: #{subscription.metadata.inspect}"
    
    # Try to find provider by stripe_customer_id first
    provider = Provider.find_by(stripe_customer_id: subscription.customer)
    
    # If not found, try to find by customer ID in metadata
    unless provider && subscription.metadata.present?
      provider_id = subscription.metadata['provider_id']
      provider = Provider.find_by(id: provider_id) if provider_id.present?
    end
    
    # If still not found, try to find by customer email
    unless provider
      Stripe.api_key ||= Rails.configuration.stripe[:secret_key]
      begin
        customer = Stripe::Customer.retrieve(subscription.customer)
        if customer.email.present?
          provider = Provider.find_by(email: customer.email)
          # Update provider with customer ID if found
          provider.update(stripe_customer_id: customer.id) if provider
        end
      rescue Stripe::StripeError => e
        Rails.logger.error "Failed to retrieve Stripe customer: #{e.message}"
      end
    end
    
    if provider
      # Create or update sponsorship
      sponsorship = provider.sponsorships.find_or_initialize_by(
        stripe_subscription_id: subscription.id
      )
      
      # Determine tier from price ID or plan
      tier = determine_tier_from_price_id_or_plan(subscription, nil)
      
      sponsorship.update!(
        tier: tier,
        stripe_customer_id: subscription.customer,
        status: 'active',
        starts_at: Time.at(subscription.current_period_start),
        ends_at: Time.at(subscription.current_period_end),
        amount_paid: subscription.items.data.first.price.unit_amount / 100.0
      )
      
      sponsorship.activate!
      Rails.logger.info "Subscription sponsorship activated: #{sponsorship.id} for provider #{provider.name}"
    else
      Rails.logger.warn "No provider found for subscription #{subscription.id} with customer #{subscription.customer}"
      Rails.logger.warn "Subscription metadata: #{subscription.metadata.inspect}"
    end
  end
  
  def handle_subscription_updated(subscription)
    Rails.logger.info "Subscription updated: #{subscription.id}"
    
    sponsorship = Sponsorship.find_by(stripe_subscription_id: subscription.id)
    
    if sponsorship
      if subscription.status == 'active'
        # Determine tier from price ID
        tier = determine_tier_from_price_id_or_plan(subscription, nil)
        
        sponsorship.update!(
          tier: tier,
          status: 'active',
          ends_at: Time.at(subscription.current_period_end)
        )
        sponsorship.activate!
      elsif subscription.status == 'canceled' || subscription.cancel_at_period_end
        sponsorship.cancel!
      end
    end
  end
  
  def handle_subscription_deleted(subscription)
    Rails.logger.info "Subscription deleted: #{subscription.id}"
    
    sponsorship = Sponsorship.find_by(stripe_subscription_id: subscription.id)
    
    if sponsorship
      sponsorship.cancel!
    end
  end
  
  def handle_invoice_payment_succeeded(invoice)
    Rails.logger.info "Invoice payment succeeded: #{invoice.id}"
    
    # This is for recurring subscription payments
    return unless invoice.subscription.present?
    
    subscription_id = invoice.subscription
    sponsorship = Sponsorship.find_by(stripe_subscription_id: subscription_id)
    
    if sponsorship
      # Update the sponsorship end date for the new billing period
      subscription = Stripe::Subscription.retrieve(subscription_id)
      sponsorship.update!(
        ends_at: Time.at(subscription.current_period_end),
        amount_paid: invoice.amount_paid / 100.0
      )
      sponsorship.activate! # Re-activate to update provider
      Rails.logger.info "Sponsorship renewed: #{sponsorship.id}"
    end
  end
  
  def handle_invoice_payment_failed(invoice)
    Rails.logger.info "Invoice payment failed: #{invoice.id}"
    
    # This is for failed recurring subscription payments
    return unless invoice.subscription.present?
    
    subscription_id = invoice.subscription
    sponsorship = Sponsorship.find_by(stripe_subscription_id: subscription_id)
    
    if sponsorship
      # You might want to notify the provider or mark as past due
      Rails.logger.warn "Sponsorship payment failed for: #{sponsorship.id}"
      # Optionally: send notification email to provider
    end
  end
  
  def determine_tier_from_price(amount_in_cents)
    case amount_in_cents
    when 99_00
      'basic'
    when 199_00
      'premium'
    when 299_00
      'featured'
    else
      'basic'
    end
  end
  
  # Determine tier from price ID or plan name
  # Maps to new tier names: featured, sponsor, partner
  def determine_tier_from_price_id_or_plan(subscription, plan = nil)
    # First try to get from plan metadata
    if plan.present?
      case plan.to_s.downcase
      when 'featured'
        return 'featured'
      when 'sponsor'
        return 'sponsor'
      when 'partner'
        return 'partner'
      end
    end
    
    # Fallback to price ID from environment variables (check both monthly and annual)
    price_id = subscription.items.data.first&.price&.id
    
    if price_id
      # Monthly prices
      featured_price_monthly = ENV['STRIPE_PRICE_FEATURED']
      sponsor_price_monthly = ENV['STRIPE_PRICE_SPONSOR']
      partner_price_monthly = ENV['STRIPE_PRICE_PARTNER']
      
      # Annual (10-month) prices
      featured_price_annual = ENV['STRIPE_PRICE_FEATURED_ANNUAL']
      sponsor_price_annual = ENV['STRIPE_PRICE_SPONSOR_ANNUAL']
      partner_price_annual = ENV['STRIPE_PRICE_PARTNER_ANNUAL']
      
      case price_id
      when featured_price_monthly, featured_price_annual
        return 'featured'
      when sponsor_price_monthly, sponsor_price_annual
        return 'sponsor'
      when partner_price_monthly, partner_price_annual
        return 'partner'
      end
    end
    
    # Fallback to amount if price IDs not available
    amount = subscription.items.data.first&.price&.unit_amount
    if amount
      # Use amount-based mapping (adjust these values based on your actual pricing)
      case amount
      when 0..100_00
        return 'featured'
      when 100_01..200_00
        return 'sponsor'
      else
        return 'partner'
      end
    end
    
    # Default fallback
    Rails.logger.warn "Could not determine tier for subscription #{subscription.id}, defaulting to 'featured'"
    'featured'
  end
end

