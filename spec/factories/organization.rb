FactoryGirl.define do
  factory :organization do
    sequence(:department_name) { |n| "department_name-#{n}" }
    sequence(:agency_name) { |n| "agency_name-#{n}" }
    sequence(:team_name) { |n| "team_name-#{n}" }
  end
end
