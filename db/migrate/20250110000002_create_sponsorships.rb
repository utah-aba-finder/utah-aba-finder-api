class CreateSponsorships < ActiveRecord::Migration[7.1]
  def change
    create_table :sponsorships do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :stripe_payment_intent_id
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.string :tier, null: false # 'basic', 'premium', 'featured'
      t.decimal :amount_paid, precision: 10, scale: 2
      t.datetime :starts_at
      t.datetime :ends_at
      t.datetime :cancelled_at
      t.string :status, default: 'pending' # 'pending', 'active', 'cancelled', 'expired'
      t.text :notes
      
      t.timestamps
    end
    
    add_index :sponsorships, :stripe_payment_intent_id
    add_index :sponsorships, :stripe_subscription_id
    add_index :sponsorships, :stripe_customer_id
    add_index :sponsorships, :status
    add_index :sponsorships, :tier
  end
end

