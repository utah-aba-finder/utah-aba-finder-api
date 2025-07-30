class AddInHomeOnlyToProviders < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:providers, :in_home_only)
      add_column :providers, :in_home_only, :boolean, default: false, null: false
    end
  end
end
