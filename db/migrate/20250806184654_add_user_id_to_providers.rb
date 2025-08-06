class AddUserIdToProviders < ActiveRecord::Migration[7.1]
  def change
    add_reference :providers, :user, null: true, foreign_key: true
  end
end
