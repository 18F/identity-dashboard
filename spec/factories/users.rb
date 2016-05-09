FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "user#{n}@example.com" }
    sequence(:first_name) {|n| "FirstName#{n}" }
    sequence(:last_name) {|n| "LastName#{n}" }
  end
end
