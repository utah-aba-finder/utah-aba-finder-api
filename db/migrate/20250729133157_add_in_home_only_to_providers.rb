class AddInHomeOnlyToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :in_home_only, :boolean, default: false, null: false
  end
end
