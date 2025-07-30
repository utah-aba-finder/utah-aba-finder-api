FactoryBot.define do
  factory :client do
    sequence(:name) { |n| "test_client_#{n}" }
    sequence(:email) { |n| "test_client_#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    api_key { SecureRandom.hex }
  end
end
