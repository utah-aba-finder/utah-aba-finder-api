class ChangeWaitlistFieldsToString < ActiveRecord::Migration[7.1]
  def change
    # Change waitlist fields from boolean to string for better user experience
    change_column :locations, :in_home_waitlist, :string, default: "Contact for availability"
    change_column :locations, :in_clinic_waitlist, :string, default: "Contact for availability"
    
    # Add an index for better performance when filtering by waitlist status
    add_index :locations, :in_home_waitlist
    add_index :locations, :in_clinic_waitlist
  end
end
