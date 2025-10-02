FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.gov" }
    sequence(:first_name) { |n| "FirstName#{n}" }
    sequence(:last_name) { |n| "LastName#{n}" }

    trait :with_teams do
      teams { create_list(:team, 3) }
    end

    trait :with_teams_dev do
      team_memberships { create_list(:team_membership, 3, :partner_developer) }
    end

    factory :team_member do
      teams { create_list(:team, 1) }
    end

    trait :team_member do
      teams { create_list(:team, 1) }
    end

    factory :logingov_admin do
      admin { true } # TODO: delete legacy admin property
      # From the FactoryBot docs, this syntax:
      # >  works with `build`, `build_stubbed`, and `create`
      # >  (although it doesn't work well with `attributes_for`)
      team_memberships { [association(:team_membership, :logingov_admin)] }
    end

    trait :logingov_admin do
      admin { true } # TODO: delete legacy admin property
      team_memberships { [association(:team_membership, :logingov_admin)] }
    end

    factory :restricted_ic do
      sequence(:email) { |n| "user#{n}@example.com" }
    end
  end
end
