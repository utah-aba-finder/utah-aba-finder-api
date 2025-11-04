class Api::V1::PaymentsController < ApplicationController
  skip_before_action :authenticate_client, only: [:create_payment_intent]
  before_action :authenticate_user!, only: [:create_payment_intent, :create_sponsorship]
  before_action :set_provider, only: [:create_payment_intent, :create_sponsorship]
  
  # Create a Stripe payment intent for sponsorship
  def create_payment_intent
    tier = params[:tier] || params.dig(:data, :attributes, :tier) || 'basic'
    provider_id = params[:provider_id] || params.dig(:data, :attributes, :provider_id)
    
    unless Sponsorship::TIER_PRICING.key?(tier)
      render json: { error: 'Invalid sponsorship tier' }, status: :bad_request
      return
    end
    
    unless provider_id
      render json: { error: 'Provider ID is required' }, status: :bad_request
      return
    end
    
    @provider = Provider.find(provider_id)
    
    unless @current_user.can_access_provider?(@provider.id)
      render json: { error: 'Access denied. You can only purchase sponsorship for providers you manage.' }, status: :forbidden
      return
    end
    
    begin
      # Initialize Stripe (API key and version set in initializer)
      Stripe.api_key ||= Rails.configuration.stripe[:secret_key]
      
      # Create or retrieve Stripe customer
      customer = get_or_create_stripe_customer
      
      # Create payment intent
      amount = Sponsorship::TIER_PRICING[tier]
      
      payment_intent = Stripe::PaymentIntent.create(
        amount: amount,
        currency: 'usd',
        customer: customer.id,
        metadata: {
          provider_id: @provider.id,
          provider_name: @provider.name,
          tier: tier,
          user_id: @current_user.id,
          user_email: @current_user.email
        },
        description: "Sponsorship for #{@provider.name} - #{tier.capitalize} tier"
      )
      
      # Create pending sponsorship record
      sponsorship = @provider.sponsorships.create!(
        tier: tier,
        stripe_payment_intent_id: payment_intent.id,
        stripe_customer_id: customer.id,
        amount_paid: amount / 100.0,
        status: 'pending'
      )
      
      render json: {
        client_secret: payment_intent.client_secret,
        payment_intent_id: payment_intent.id,
        sponsorship_id: sponsorship.id,
        amount: amount,
        amount_in_dollars: amount / 100.0,
        tier: tier,
        provider: {
          id: @provider.id,
          name: @provider.name
        }
      }, status: :ok
      
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error: #{e.message}"
      render json: { error: "Payment processing error: #{e.message}" }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Payment intent creation failed: #{e.message}"
      render json: { error: 'Failed to create payment intent' }, status: :internal_server_error
    end
  end
  
  # Confirm sponsorship after payment (called from webhook or manually)
  def confirm_sponsorship
    payment_intent_id = params[:payment_intent_id]
    
    unless payment_intent_id.present?
      render json: { error: 'Payment intent ID is required' }, status: :bad_request
      return
    end
    
    begin
      sponsorship = Sponsorship.find_by(stripe_payment_intent_id: payment_intent_id)
      
      unless sponsorship
        render json: { error: 'Sponsorship not found' }, status: :not_found
        return
      end
      
      # Verify payment with Stripe (API key and version set in initializer)
      Stripe.api_key ||= Rails.configuration.stripe[:secret_key]
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
      
      if payment_intent.status == 'succeeded'
        sponsorship.activate!
        
        render json: {
          success: true,
          message: 'Sponsorship activated successfully',
          sponsorship: {
            id: sponsorship.id,
            tier: sponsorship.tier,
            status: sponsorship.status,
            ends_at: sponsorship.ends_at,
            provider: {
              id: sponsorship.provider.id,
              name: sponsorship.provider.name,
              is_sponsored: sponsorship.provider.is_sponsored
            }
          }
        }, status: :ok
      else
        render json: { error: "Payment not completed. Status: #{payment_intent.status}" }, status: :unprocessable_entity
      end
      
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error: #{e.message}"
      render json: { error: "Payment verification error: #{e.message}" }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Sponsorship confirmation failed: #{e.message}"
      render json: { error: 'Failed to confirm sponsorship' }, status: :internal_server_error
    end
  end
  
  private
  
  def set_provider
    provider_id = params[:provider_id] || params.dig(:data, :attributes, :provider_id)
    @provider = Provider.find(provider_id) if provider_id
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Provider not found' }, status: :not_found
  end
  
  def get_or_create_stripe_customer
    # Check if provider already has a Stripe customer ID
    if @provider.stripe_customer_id.present?
      begin
        customer = Stripe::Customer.retrieve(@provider.stripe_customer_id)
        return customer
      rescue Stripe::StripeError
        # Customer doesn't exist, create a new one
      end
    end
    
    # Create new Stripe customer (API version set in initializer)
    customer = Stripe::Customer.create(
      email: @provider.email || @current_user.email,
      name: @provider.name,
      metadata: {
        provider_id: @provider.id,
        user_id: @current_user.id
      }
    )
    
    # Update provider with customer ID
    @provider.update(stripe_customer_id: customer.id)
    
    customer
  end
end
