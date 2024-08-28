class CreateProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :providers do |t|
      t.string :name
      t.string :website
      t.string :email
      t.string :cost
      t.float :min_age
      t.float :max_age
      t.string :waitlist
      t.string :at_home_services
      t.string :in_clinic_services
      t.string :telehealth_services
      t.string :spanish_speakers

      t.timestamps
    end
  end
end
