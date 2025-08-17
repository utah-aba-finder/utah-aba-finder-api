FactoryBot.define do
  factory :provider do
    sequence(:name) { |n| "Provider #{n}" }
    sequence(:email) { |n| "provider#{n}@example.com" }
    website { "https://example.com" }
    cost { "Contact for pricing" }
    min_age { 2.0 }
    max_age { 18.0 }
    waitlist { "Contact for availability" }
    at_home_services { "ABA Therapy" }
    in_clinic_services { "Assessment" }
    telehealth_services { "Consultation" }
    spanish_speakers { "Yes" }
    status { :approved }
    in_home_only { false }
    service_delivery { { "in_home" => true, "in_clinic" => true, "telehealth" => true } }
    
    trait :pending do
      status { :pending }
    end
    
    trait :denied do
      status { :denied }
    end
    
    trait :in_home_only do
      in_home_only { true }
    end
  end
end 