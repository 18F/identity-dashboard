FactoryBot.define do
  factory :service_provider do
    sequence(:friendly_name) { |n| "test-service_provider-#{n}" }
    sequence(:issuer) { |n| "urn:gov:gsa:SAML:2.0.profiles:sp:sso:DEPT:APP-#{n}" }
    sequence(:description) { |n| "test service_provider description #{n}" }
    association :user, factory: :user
    association :agency, factory: :agency
    help_text do
      { 'sign_in': { en: '<b>Some sign-in help text</b>' },
        'sign_up': { en: '<b>Some sign-up help text</b>' },
        'forgot_password': { en: '<b>Some forgot password help text</b>' } }
    end

    trait :saml do
      identity_protocol { 1 }
    end

    trait :team do
      association :team, factory: :team
    end

    trait :with_users_team do
      after(:build) do |service_provider|
        team = service_provider.user&.teams[1] || create(:team)
        service_provider.team = team
      end
    end

  end
end
