class ChangeWaitlistFieldsToText < ActiveRecord::Migration[7.1]
  def change
    change_column :locations, :in_home_waitlist, :text
    change_column :locations, :in_clinic_waitlist, :text
  end
end
