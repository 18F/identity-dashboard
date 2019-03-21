FactoryBot.define do
  factory :service_provider do
    ial { 1 }
    sequence(:friendly_name) { |n| "test-service_provider-#{n}" }
    sequence(:issuer) { |n| "urn:gov:gsa:SAML:2.0.profiles:sp:sso:DEPT:APP-#{n}" }
    sequence(:description) { |n| "test service_provider description #{n}" }
    association :user, factory: :user
  end
end
