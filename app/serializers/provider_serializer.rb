class ProviderSerializer
  include JSONAPI::Serializer

  def self.format_providers(providers)
    {
      data: providers.map do |provider|
        {
          id: provider.id,
          type: "provider",
          states: provider.counties.map {|county| county.state&.name}.compact.uniq,
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
            "counties_served": provider.counties.map do |area|
              {
                "county_id" => area.id,
                "county_name" => area.name
              }
            end,
            "min_age": provider.min_age,
            "max_age": provider.max_age,
            "waitlist": provider.waitlist,
            "telehealth_services": provider.telehealth_services,
            "spanish_speakers": provider.spanish_speakers,
            "at_home_services": provider.at_home_services,
            "in_clinic_services": provider.in_clinic_services,
            "logo": provider.logo,
            "updated_last": provider.updated_at,
            "status": provider.status
          }
        }
      end
    }
  end
end