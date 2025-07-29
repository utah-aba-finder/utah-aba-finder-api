class InsuranceSerializer
  include JSONAPI::Serializer

  def self.format_insurances(insurances)
    {
      data: insurances.map do |i|
        {
          id: i.id,
          type: "insurance",
          attributes: {
            "name": i.name
          }
        }
      end
    }
  end
end