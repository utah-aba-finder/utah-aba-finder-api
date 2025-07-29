class TransferOldCountiesToNewOnes < ActiveRecord::Migration[7.1]
  def up
    # Mapping cities to counties based on previous entries
    city_to_county_mapping = {
      "SLC" => "Salt Lake",
      "Salt Lake City" => "Salt Lake",
      "Bountiful" => "Davis",
      "Lehi" => "Utah",
      "Midvale" => "Salt Lake",
      "Orem" => "Utah",
      "St. George" => "Washington",
      "Sandy" => "Salt Lake",
      "Draper" => "Salt Lake",
      "Cottonwood Heights" => "Salt Lake",
      "South Jordan" => "Salt Lake",
      "Smithfield" => "Cache",
      "Plymouth" => "Box Elder",
      "West Jordan" => "Salt Lake",
      "Brigham City" => "Box Elder",
      "Bear River" => "Box Elder",
      "Richfield" => "Sevier",
      "Riverdale" => "Weber",
      "Cedar City" => "Iron",
      "Price" => "Carbon",
      "Nephi" => "Juab",
      "Delta" => "Millard",
      "Provo" => "Utah",
      "Ogden" => "Weber"
    }

    OldCounty.find_each do |old_county|
      provider = old_county.provider
      counties = old_county.counties_served.split(',').map(&:strip)
      default_county = County.find_by(name: "Contact Us")

      counties.each do |county_name|
        county = County.find_by(name: county_name)

        if county
          provider.counties << county unless provider.counties.include?(county)
        else
          # If no direct county found, check the mapping for a city
          mapped_county_name = city_to_county_mapping[county_name]

          if mapped_county_name
            mapped_county = County.find_by(name: mapped_county_name)
            provider.counties << mapped_county unless provider.counties.include?(mapped_county)
          else
            # If no match in mapping, use default county
            provider.counties << default_county unless provider.counties.include?(default_county)
          end
        end
      end
    end
  end
end