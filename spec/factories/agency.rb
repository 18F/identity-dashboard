FactoryBot.define do
  factory :agency do
    sequence(:name) { |n| "test-agency-#{n}" }
  end
end
