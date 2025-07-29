class StateSerializer
  include JSONAPI::Serializer

  def self.format_states(states)
    {
      data: states.map do |s|
        {
          id: s.id,
          type: "State",
          attributes: {
            "name": s.name,
            "abbreviation": s.abbreviation
          }
        }
      end
    }
  end
end