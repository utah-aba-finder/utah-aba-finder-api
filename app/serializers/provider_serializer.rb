class ProviderSerializer
  include JSONAPI::Serializer

  def self.format_providers(providers)
    {
      data: providers.map do |provider|
        {
          id: provider.id,
          type: "provider",
          states: get_provider_states(provider),
          attributes: {
            "name": provider.name,
            "provider_type": provider.practice_types.map do |type|
              {
                id: type.id,
                name: type.name
              }
            end,
            "locations": provider.locations.map do |location| 
              {
              id: location.id,
              name: location.name,
              address_1: location.address_1,
              address_2: location.address_2,
              city: location.city,
              state: location.state,
              zip: location.zip,
              phone: location.phone,
              services: location.practice_types.map do |type|
                {
                  id: type.id,
                  name: type.name
                }
              end,
              in_home_waitlist: location.in_home_waitlist,
              in_clinic_waitlist: location.in_clinic_waitlist
              }
            end,
            "website": provider.website,
            "email": provider.email,
            "cost": provider.cost,
            
            "insurance": provider.provider_insurances.where(accepted: true).map do |provider_insurance|
              {
                name: provider_insurance.insurance.name, 
                id: provider_insurance.insurance_id,
                accepted: provider_insurance.accepted
              }
            end,
            # "counties_served": provider.old_counties.map { |area| {county: area.counties_served} },
            "counties_served": get_provider_counties(provider),
            "min_age": provider.min_age,
            "max_age": provider.max_age,
            "waitlist": provider.waitlist,
            "telehealth_services": provider.telehealth_services,
            "spanish_speakers": provider.spanish_speakers,
            "at_home_services": provider.at_home_services,
            "in_clinic_services": provider.in_clinic_services,
            "logo": logo_url_for(provider),
            # Backward-compatible key expected by older frontends
            "logo_url": logo_url_for(provider),
            "updated_last": provider.updated_at,
            "status": provider.status,
            "in_home_only": provider.in_home_only,
            "service_delivery": provider.service_delivery
          }
        }
      end
    }
  end

  private

  def self.get_provider_states(provider)
    # Use raw SQL to get states since the association is commented out
    sql = "SELECT DISTINCT s.name FROM states s 
            INNER JOIN counties c ON c.state_id = s.id 
            INNER JOIN counties_providers cp ON cp.county_id = c.id 
            WHERE cp.provider_id = #{provider.id}"
    
    result = ActiveRecord::Base.connection.execute(sql)
    result.values.flatten.compact.uniq
  end

  def self.get_provider_counties(provider)
    # Use raw SQL to get counties since the association is commented out
    sql = "SELECT c.id, c.name FROM counties c 
            INNER JOIN counties_providers cp ON cp.county_id = c.id 
            WHERE cp.provider_id = #{provider.id}"
    
    result = ActiveRecord::Base.connection.execute(sql)
    result.map do |row|
      {
        "county_id" => row['id'],
        "county_name" => row['name']
      }
    end
  end

  def self.logo_url_for(provider)
    # In test environment, logo attachment is not available
    return nil if Rails.env.test?
    
    # Check if provider has logo method and it's attached
    return nil unless provider.respond_to?(:logo) && provider.logo.respond_to?(:attached?) && provider.logo.attached?

    begin
      # Use direct S3 URLs since the bucket is public
      # This generates URLs like: https://asl-logos.s3.amazonaws.com/...
      blob = provider.logo.blob
      "https://asl-logos.s3.amazonaws.com/#{blob.key}"
    rescue => e
      Rails.logger.warn "Could not generate logo URL for provider #{provider.id}: #{e.message}"
      nil
    end
  end
end