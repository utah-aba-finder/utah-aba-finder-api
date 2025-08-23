class AddPhoneToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :phone, :string
  end
end
