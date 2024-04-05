FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.gov" }
    sequence(:first_name) { |n| "FirstName#{n}" }
    sequence(:last_name) { |n| "LastName#{n}" }

    trait :with_teams do
      teams { create_list(:team, 3) }
    end

    factory :team_member do
      teams { create_list(:team, 1) }
    end

    # i left this as admin for this spike as changing it would be noisy
    factory :admin do
      role { 2 }
    end

    factory :ic do
      role { 1 }
    end
  end
end
