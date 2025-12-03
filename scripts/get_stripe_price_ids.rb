#!/usr/bin/env ruby
# Script to get Price IDs from Stripe Product IDs
# Usage: rails runner scripts/get_stripe_price_ids.rb

require 'stripe'

# Set your Stripe secret key
Stripe.api_key = ENV['STRIPE_SECRET_KEY'] || Rails.configuration.stripe[:secret_key]

unless Stripe.api_key
  puts "❌ Error: STRIPE_SECRET_KEY not set"
  exit 1
end

puts "🔍 Fetching Price IDs from Stripe Products...\n\n"

products = {
  'Community Provider' => 'prod_TMa5Riv4TbmenP',  # $99
  'Provider Sponsor' => 'prod_TMa3I1kw8UPgiS',    # $59
  'Featured Provider' => 'prod_TMa0Rnb2DVhSNd'     # $25
}

products.each do |name, product_id|
  begin
    product = Stripe::Product.retrieve(product_id)
    
    # Get all prices for this product
    prices = Stripe::Price.list(product: product_id, limit: 10)
    
    puts "📦 #{name} (Product: #{product_id})"
    puts "   Name: #{product.name}"
    
    if prices.data.empty?
      puts "   ⚠️  No prices found for this product!"
    else
      prices.data.each do |price|
        amount = price.unit_amount ? "$#{price.unit_amount / 100.0}" : "N/A"
        interval = price.recurring&.interval || "one-time"
        puts "   💰 Price ID: #{price.id}"
        puts "      Amount: #{amount} (#{interval})"
        
        # This is the active price we want
        if price.active
          puts "      ✅ Active price"
        end
      end
    end
    puts ""
  rescue Stripe::StripeError => e
    puts "❌ Error fetching product #{product_id}: #{e.message}\n\n"
  end
end

puts "\n📋 Recommended Environment Variables:\n"
puts "Based on your pricing tiers, set these in Heroku:\n\n"

# Map based on the pricing provided
# Community Provider ($99) -> Partner tier (highest)
# Provider Sponsor ($59) -> Sponsor tier (middle)  
# Featured Provider ($25) -> Featured tier (lowest)

puts "# For Partner tier ($99):"
puts "heroku config:set STRIPE_PRICE_PARTNER=<price_id_from_prod_TMa5Riv4TbmenP>"
puts ""
puts "# For Sponsor tier ($59):"
puts "heroku config:set STRIPE_PRICE_SPONSOR=<price_id_from_prod_TMa3I1kw8UPgiS>"
puts ""
puts "# For Featured tier ($25):"
puts "heroku config:set STRIPE_PRICE_FEATURED=<price_id_from_prod_TMa0Rnb2DVhSNd>"
puts ""
puts "💡 Copy the Price IDs from the output above and replace <price_id_from_...>"

