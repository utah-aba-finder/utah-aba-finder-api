namespace :providers do
  desc "Migrate existing provider data to populate new fields"
  task migrate_data: :environment do
    puts "Starting provider data migration..."
    
    Provider.find_each do |provider|
      puts "Processing provider: #{provider.name}"
      
      # Determine in_home_only based on existing data
      in_home_only = determine_in_home_only(provider)
      
      # Determine service_delivery based on existing fields
      service_delivery = determine_service_delivery(provider)
      
      # Determine service_area (default to Utah for now)
      service_area = { states_served: ['UT'], counties_served: [] }
      
      # Update the provider
      provider.update!(
        in_home_only: in_home_only,
        service_delivery: service_delivery,
        service_area: service_area
      )
      
      puts "  - in_home_only: #{in_home_only}"
      puts "  - service_delivery: #{service_delivery}"
      puts "  - service_area: #{service_area}"
    end
    
    puts "Provider data migration completed!"
  end
  
  private
  
  def determine_in_home_only(provider)
    # Providers are in_home_only if they have in_home_services but no in_clinic_services
    # and no locations
    has_in_home = provider.at_home_services.present? && provider.at_home_services != ""
    has_in_clinic = provider.in_clinic_services.present? && provider.in_clinic_services != ""
    has_locations = provider.locations.any?
    
    # Also check if they have telehealth but no clinic services and no locations
    has_telehealth = provider.telehealth_services.present? && provider.telehealth_services != ""
    
    (has_in_home || has_telehealth) && !has_in_clinic && !has_locations
  end
  
  def determine_service_delivery(provider)
    in_home = provider.at_home_services.present? && provider.at_home_services != ""
    in_clinic = provider.in_clinic_services.present? && provider.in_clinic_services != ""
    telehealth = provider.telehealth_services.present? && provider.telehealth_services != ""
    
    {
      'in_home' => in_home,
      'in_clinic' => in_clinic,
      'telehealth' => telehealth
    }
  end
end 