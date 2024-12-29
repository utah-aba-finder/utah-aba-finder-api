class CountySerializer
  include JSONAPI::Serializer

  def self.format_counties(counties)
    {
      data: counties.map do |c|
        {
          id: c.id,
          type: "County",
          attributes: {
            "name": c.name,
            "state": c.state.name
          }
        }
      end
    }
  end
end