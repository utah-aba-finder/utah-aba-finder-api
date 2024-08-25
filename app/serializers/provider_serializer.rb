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
            "website": provider.website,
            "address": provider.address,
            "locations": provider.locations.map do |location| 
              {
              name: location.name,
              phone: location.phone
              }
            end,
            "phone": provider.phone,
            "email": provider.email,
            "insurance": provider.insurance.map { |insurance| insurance.name},
            "areas_served": provider.areas_served.map { |area| area.name},
            "cost": provider.cost,
            "ages_served": provider.ages_served,
            "waitlist": provider.waitlist,
            "telehealth_services": provider.telehealth_services,
            "spanish_speakers": provider.spanish_speakers
          }
        }
      end
    }
  end
end