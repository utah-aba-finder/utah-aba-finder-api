class AddCategoryToProviders < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:providers, :category)
      add_column :providers, :category, :string, default: 'aba_therapy'
      add_index :providers, :category
    end
  end
end 
