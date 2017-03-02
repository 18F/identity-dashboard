FactoryGirl.define do
  factory :service_provider do
    agency 'Test agency'
    sequence(:friendly_name) { |n| "test-service_provider-#{n}" }
    sequence(:issuer) { |n| "test-service_provider-#{n}" }
    sequence(:description) { |n| "test service_provider description #{n}" }
    association :user, factory: :user
  end
end
