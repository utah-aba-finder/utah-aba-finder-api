class AddCategoryToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :category, :string, default: 'aba_therapy'
    add_index :providers, :category
  end
end 
