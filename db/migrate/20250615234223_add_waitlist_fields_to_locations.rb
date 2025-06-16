class AddWaitlistFieldsToLocations < ActiveRecord::Migration[7.1]
  def change
    add_column :locations, :in_home_waitlist, :boolean, default: false
    add_column :locations, :in_clinic_waitlist, :boolean, default: false
  end
end
