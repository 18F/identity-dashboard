FactoryGirl.define do
  factory :user_group do
    sequence(:name) { |n| "department_name-#{n}" }
    sequence(:description) { |n| "agency_name-#{n}" }
  end
end
