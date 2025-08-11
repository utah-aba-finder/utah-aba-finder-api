class CreateProviderAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :provider, null: false, foreign_key: true
      t.string :assigned_by, null: false  # Track who made the assignment
      t.text :notes  # Optional notes about the assignment

      t.timestamps
    end
    
    add_index :provider_assignments, [:user_id, :provider_id], unique: true, name: 'index_provider_assignments_on_user_id_and_provider_id'
    add_index :provider_assignments, :assigned_by
  end
end
