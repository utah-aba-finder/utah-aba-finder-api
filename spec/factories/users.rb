FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { "user" }
    
    trait :super_admin do
      role { "super_admin" }
    end
    
    trait :provider_admin do
      role { "provider_admin" }
    end
  end
end
