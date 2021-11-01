FactoryBot.define do
  factory :service_provider do
    attribute_bundle { %w[email] }
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
      identity_protocol { :saml }
      acs_url {'https://fake.gov/test/saml/acs'}
      assertion_consumer_logout_service_url {'https://fake.gov/test/saml/logout'}
      sp_initiated_login_url {'https://fake.gov/test/saml/sp_login'}
      signed_response_message_requested {1}
    end

    trait :with_oidc_jwt do
      identity_protocol { :openid_connect_private_key_jwt }
    end

    trait :with_oidc_pkce do
      identity_protocol { :openid_connect_pkce }
    end

    trait :with_ial_2 do
      ial { 2 }
    end

    trait :with_ial_2_bundle do
      attribute_bundle { %w[email first_name last_name] }
    end

    trait :with_team do
      association :team, factory: :team
    end

    trait :with_users_team do
      after(:build) do |service_provider|
        team = service_provider.user&.teams[0]
        service_provider.team = team
      end
    end
  end
end
