class CreateUtahCounties < ActiveRecord::Migration[7.1]
  UTAH_COUNTIES = [
    "Beaver",
    "Box Elder",
    "Cache",
    "Carbon",
    "Daggett",
    "Davis",
    "Duchesne",
    "Emery",
    "Garfield",
    "Grand",
    "Iron",
    "Juab",
    "Kane",
    "Millard",
    "Morgan",
    "Piute",
    "Rich",
    "Salt Lake",
    "San Juan",
    "Sanpete",
    "Sevier",
    "Summit",
    "Tooele",
    "Uintah",
    "Utah",
    "Wasatch",
    "Washington",
    "Wayne",
    "Weber",
    "Contact Us"
  ].freeze

  def up
    utah = State.find_or_create_by!(name: 'Utah', abbreviation: 'UT')

    UTAH_COUNTIES.each do |county_name|
      County.find_or_create_by!(name: county_name, state: utah)
    end
  end
end