class RemoveLogoFromProviders < ActiveRecord::Migration[7.1]
  def change
    remove_column :providers, :logo, :string
  end
end
