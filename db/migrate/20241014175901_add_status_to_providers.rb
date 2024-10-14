class AddStatusToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :status, :integer, default: 1, null: false

    # Update existing providers to be approved
    # Best practice to do logic in reversible block incase of rollbacks
    reversible do |dir|
      dir.up do
        Provider.update_all(status: 2) # approved
      end
    end
  end
end
