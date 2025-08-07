#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

# Test the assign_provider_to_user endpoint
def test_endpoint
  url = URI('https://utah-aba-finder-api-c9d143f02ce8.herokuapp.com/api/v1/providers/assign_provider_to_user')
  
  # Test data
  data = {
    provider_id: 1095,
    user_id: 38  # This is the user ID for mfielder@abacenters.com
  }
  
  # Headers
  headers = {
    'Content-Type' => 'application/json',
    'Authorization' => 'be6205db57ce01863f69372308c41e3a'  # API key from the logs
  }
  
  # Make the request
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(url, headers)
  request.body = data.to_json
  
  puts "Making request to: #{url}"
  puts "Headers: #{headers}"
  puts "Data: #{data}"
  
  response = http.request(request)
  
  puts "Response code: #{response.code}"
  puts "Response body: #{response.body}"
  
  return response
end

# Run the test
test_endpoint 