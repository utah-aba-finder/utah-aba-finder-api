class ProviderSerializer
  include JSONAPI::Serializer

  def self.format_providers(providers)
    {
      data: providers.map do |provider|
        {
          id: provider.id,
          type: "provider",
          attributes: {
            "name": provider.name,
            "locations": provider.locations.map do |location| 
              {
              id: location.id,
              name: location.name,
              address_1: location.address_1,
              address_2: location.address_2,
              city: location.city,
              state: location.state,
              zip: location.zip,
              phone: location.phone
              }
            end,
            "website": provider.website,
            "email": provider.email,
            "cost": provider.cost,
            
            "insurance": provider.provider_insurances.map do |provider_insurance|
              {
                name: provider_insurance.insurance.name, 
                id: provider_insurance.id
              }
            end,
            "counties_served": provider.counties.map { |area| {county: area.counties_served} },
            "min_age": provider.min_age,
            "max_age": provider.max_age,
            "waitlist": provider.waitlist,
            "telehealth_services": provider.telehealth_services,
            "spanish_speakers": provider.spanish_speakers,
            "at_home_services": provider.at_home_services,
            "in_clinic_services": provider.in_clinic_services,
            "logo": provider.logo
          }
        }
      end
    }
  end
end