require 'csv'

CSV.foreach(Rails.root.join('db', 'data', 'insurances.csv'), headers: true) do |row|
  Insurance.create!(name: row['name'])
end

CSV.foreach(Rails.root.join('db', 'data', 'providers.csv'), headers: true) do |row|
  Provider.create!(
    name: row['name'],
    website: row['website'],
    email: row['email'],
    cost: row['cost'],
    min_age: row['min_age'],
    max_age: row['max_age'],
    waitlist: row['waitlist'],
    telehealth: row['telehealth'],
    at_home_services: row['in_home_services'],
    in_clinic_services: row['in_clinic_services'],
    telehealth_services: row['telehealth_services'],
    spanish_speakers: row['spanish_speakers']
  )
end

CSV.foreach(Rails.root.join('db', 'data', 'providers_insurances.csv'), headers: true) do |row|
  ProvidersInsurance.create!(
    provider_id: row['provider_id'].to_i,
    insurance_id: row['insurance_id'].to_i
  )
end

CSV.foreach(Rails.root.join('db', 'data', 'locations.csv'), headers: true) do |row|
  Location.create!(
    provider_id: row['provider_id'].to_i,
    name: row['location_name'],
    phone: row['phone'],
    email: row['email'],
    address_1: row['address_1'],
    address_2: row['address_2'],
    city: row['city'],
    state: row['state'],
    zip: row['zip']
  )
end

CSV.foreach(Rails.root.join('db', 'data', 'counties_served.csv'), headers: true) do |row|
  Counties.create!(
    provider_id: row['provider_id'],
    counties_served: row['counties_served']
  )
  counties.save
end