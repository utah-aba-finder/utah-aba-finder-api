class CreateEmailTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :email_templates do |t|
      t.string :name, null: false
      t.text :content, null: false
      t.string :template_type, null: false, default: 'html'
      t.string :description
      t.string :subject

      t.timestamps
    end
    
    add_index :email_templates, [:name, :template_type], unique: true
  end
end
