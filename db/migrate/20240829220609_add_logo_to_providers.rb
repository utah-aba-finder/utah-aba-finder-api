class AddLogoToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :logo, :string
  end
end
