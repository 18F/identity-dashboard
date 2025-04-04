FactoryBot.define do
  factory :service_provider do
    attribute_bundle { %w[email] }
    sequence(:friendly_name) { |n| "test-service_provider-#{n}" }
    sequence(:issuer) { |n| "urn:gov:gsa:SAML:2.0.profiles:sp:sso:DEPT:APP-#{n}" }
    sequence(:description) { |n| "test service_provider description #{n}" }
    association :user, factory: :user
    association :agency, factory: :agency
    help_text do
      { 'sign_in': { en: '<b>Some sign-in help text</b>', es: '', fr: '', zh: '' },
        'sign_up': { en: '<b>Some sign-in help text</b>', es: '', fr: '', zh: '' },
        'forgot_password': { en: '<b>Some sign-in help text</b>', es: '', fr: '', zh: '' },
      }
    end

    trait :ready_to_activate do
      sequence(:app_name) { |n| "App Name #{n}" }
      with_team
      ial = [1, 2].sample
      send("with_ial_#{ial}")
      with_ial_2_bundle if ial == 2
      send %i[saml with_oidc_jwt with_oidc_pkce].sample
      default_aal { [1, 2, 3].sample }
      active { false }
    end

    trait :ready_to_activate_ial_1 do
      sequence(:app_name) { |n| "App Name #{n}" }
      with_team
      with_ial_1
      send %i[saml with_oidc_jwt with_oidc_pkce].sample
      default_aal { [1, 2, 3].sample }
      active { false }
    end

    trait :ready_to_activate_ial_2 do
      sequence(:app_name) { |n| "App Name #{n}" }
      with_team
      with_ial_2
      with_ial_2_bundle
      send %i[saml with_oidc_jwt with_oidc_pkce].sample
      default_aal { [1, 2, 3].sample }
      active { false }
    end

    trait :saml do
      identity_protocol { :saml }
      acs_url { 'https://fake.gov/test/saml/acs' }
      assertion_consumer_logout_service_url { 'https://fake.gov/test/saml/logout' }
      sp_initiated_login_url { 'https://fake.gov/test/saml/sp_login' }
      signed_response_message_requested { 1 }
      sequence(:return_to_sp_url) { |n| "https://test-url-#{n}" }
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

    trait :with_ial_1 do
      ial { 1 }
    end

    trait :with_ial_2_bundle do
      attribute_bundle { %w[email first_name last_name] }
    end

    trait :with_team do
      association :team, factory: :team
    end

    trait :without_signed_response_message_requested do
      signed_response_message_requested { false }
    end

    trait :with_email_id_format do
      email_nameid_format_allowed { true }
    end

    transient do
      with_team_from_user { nil }
      after(:build) do |service_provider, context|
        if context.with_team_from_user
          if context.with_team_from_user.teams.none?
            raise ArgumentError, 'FACTORY: `with_team_from_user:` requires a user with a team'
          end

          service_provider.team = context.with_team_from_user.teams[0]
        end
      end
    end
  end
end
