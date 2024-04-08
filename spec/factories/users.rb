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

    factory :admin do
      after(:create) do |user|
        user.roles.destroy_all
        create(:admin_user_role, user: user)
        user.reload
      end
    end

    factory :ic do
      after(:create) do |user|
        user.roles.destroy_all
        create(:ic_user_role, user: user)
        user.reload
      end
    end

    factory :restricted_ic do
      after(:create) do |user|
        user.roles.destroy_all
        create(:user_role, user: user)
        user.reload
      end
    end
  end
end
