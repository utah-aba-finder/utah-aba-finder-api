class AddActiveProviderIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :active_provider_id, :integer
    add_index :users, :active_provider_id
    add_foreign_key :users, :providers, column: :active_provider_id
  end
end
