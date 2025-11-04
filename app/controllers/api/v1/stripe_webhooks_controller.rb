class Api::V1::StripeWebhooksController < ApplicationController
  skip_before_action :authenticate_client
  
  # Stripe webhook endpoint
  def handle
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.configuration.stripe[:webhook_secret]
    
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
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
    
    provider = Provider.find_by(stripe_customer_id: subscription.customer)
    
    if provider
      # Create or update sponsorship
      sponsorship = provider.sponsorships.find_or_initialize_by(
        stripe_subscription_id: subscription.id
      )
      
      # Determine tier from subscription price
      tier = determine_tier_from_price(subscription.items.data.first.price.unit_amount)
      
      sponsorship.update!(
        tier: tier,
        stripe_customer_id: subscription.customer,
        status: 'active',
        starts_at: Time.at(subscription.current_period_start),
        ends_at: Time.at(subscription.current_period_end),
        amount_paid: subscription.items.data.first.price.unit_amount / 100.0
      )
      
      sponsorship.activate!
      Rails.logger.info "Subscription sponsorship activated: #{sponsorship.id}"
    end
  end
  
  def handle_subscription_updated(subscription)
    Rails.logger.info "Subscription updated: #{subscription.id}"
    
    sponsorship = Sponsorship.find_by(stripe_subscription_id: subscription.id)
    
    if sponsorship
      if subscription.status == 'active'
        sponsorship.update!(
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
end

