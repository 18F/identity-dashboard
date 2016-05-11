FactoryGirl.define do
  factory :application do
    sequence(:name) {|n| "test-application-#{n}" }
    sequence(:description) {|n| "test application description #{n}" }
    association :user, factory: :user
  end 
end
