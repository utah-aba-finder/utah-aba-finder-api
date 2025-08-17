class StateSerializer
  def self.format_states(states)
    {
      data: states.order(:name).map do |state|
        format_state(state)
      end
    }
  end

  def self.format_state(state)
    {
      id: state.id,
      type: "state",
      attributes: {
        name: state.name,
        abbreviation: state.abbreviation,
        counties_count: state.counties.count
      }
    }
  end
end