class CopyProviderWaitlistsToLocations < ActiveRecord::Migration[7.1]
  def up
    # Update existing locations with provider waitlist data
    Provider.includes(:locations).find_each do |provider|
      # Determine boolean value based on provider waitlist
      waitlist_value = case provider.waitlist&.downcase
                      when 'no', nil, ''
                        false
                      else
                        true
                      end
      
      # Update all locations for this provider
      provider.locations.update_all(
        in_home_waitlist: waitlist_value,
        in_clinic_waitlist: waitlist_value
      )
    end
  end
end
