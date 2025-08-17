class CreateProviderRegistrations < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_registrations do |t|
      t.string :email, null: false
      t.string :provider_name, null: false
      t.string :category, null: false
      t.string :status, default: 'pending', null: false
      t.jsonb :submitted_data, default: {}
      t.text :admin_notes
      t.datetime :reviewed_at
      t.references :reviewed_by, null: true, foreign_key: { to_table: :users }
      t.text :rejection_reason
      t.boolean :is_processed, default: false, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :provider_registrations, :email
    add_index :provider_registrations, :category
    add_index :provider_registrations, :status
    add_index :provider_registrations, :is_processed
    add_index :provider_registrations, :reviewed_by_id
  end
end 
