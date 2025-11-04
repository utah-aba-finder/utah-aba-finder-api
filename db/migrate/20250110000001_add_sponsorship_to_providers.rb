class AddSponsorshipToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :is_sponsored, :boolean, default: false, null: false
    add_column :providers, :sponsored_until, :datetime
    add_column :providers, :sponsorship_tier, :string # 'basic', 'premium', 'featured'
    add_column :providers, :stripe_customer_id, :string
    add_column :providers, :stripe_subscription_id, :string
    
    add_index :providers, :is_sponsored
    add_index :providers, :sponsored_until
    add_index :providers, :sponsorship_tier
    add_index :providers, :stripe_customer_id
  end
end

