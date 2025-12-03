class CreateProviderViews < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_views do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :fingerprint, null: false
      t.date :view_date, null: false

      t.timestamps
    end
    
    add_index :provider_views, [:provider_id, :fingerprint, :view_date], unique: true, name: 'index_provider_views_unique'
  end
end
