class ProviderSerializer
  include JSONAPI::Serializer

  def self.format_providers(providers)
    {
      data: providers.map do |provider|
        # binding.pry
        {
          id: provider.id,
          type: "provider",
          # attributes need to be updated
          attributes: {
            "name": provider.name,
            "locations": provider.locations.map do |location| 
              {
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
            
            "insurance": provider.insurances.map { |insurance| {name: insurance.name} },
            "counties_served": provider.counties.map { |area| {county: area.counties_served} },
            "min_age": provider.min_age,
            "max_age": provider.max_age,
            "waitlist": provider.waitlist,
            "telehealth_services": provider.telehealth_services,
            "spanish_speakers": provider.spanish_speakers,
            "at_home_services": provider.at_home_services,
            "in_clinic_services": provider.in_clinic_services,
            # "logo": provider.logo
          }
        }
      end
    }
  end
end