FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:first_name) { |n| "FirstName#{n}" }
    sequence(:last_name) { |n| "LastName#{n}" }

    trait :with_groups do
      groups { create_list(:group, 3) }
    end

    factory :admin do
      admin { true }
    end
  end
end
