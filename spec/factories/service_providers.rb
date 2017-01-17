FactoryGirl.define do
  factory :service_provider do
    sequence(:friendly_name) { |n| "test-service_provider-#{n}" }
    sequence(:issuer) { |n| "test-service_provider-#{n}" }
    sequence(:description) { |n| "test service_provider description #{n}" }
    association :user, factory: :user
    association :agency, factory: :agency
  end
end
