# Stripe configuration
Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'] || Rails.application.credentials.stripe&.publishable_key,
  secret_key: ENV['STRIPE_SECRET_KEY'] || Rails.application.credentials.stripe&.secret_key,
  webhook_secret: ENV['STRIPE_WEBHOOK_SECRET'] || Rails.application.credentials.stripe&.webhook_secret
}

# Set Stripe API version to match webhook configuration
Stripe.api_version = '2025-10-29.clover'

# Set API key if available
if Rails.configuration.stripe[:secret_key].present?
  Stripe.api_key = Rails.configuration.stripe[:secret_key]
end

