class CreateProviderClaimRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_claim_requests do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :claimer_email, null: false
      t.string :status, default: 'pending', null: false
      t.bigint :reviewed_by_id
      t.datetime :reviewed_at
      t.text :admin_notes
      t.text :rejection_reason
      t.boolean :is_processed, default: false, null: false

      t.timestamps
    end

    add_index :provider_claim_requests, :claimer_email
    add_index :provider_claim_requests, :status
    add_index :provider_claim_requests, [:provider_id, :status]
    add_index :provider_claim_requests, :is_processed
    add_foreign_key :provider_claim_requests, :users, column: :reviewed_by_id
  end
end
