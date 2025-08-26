FactoryBot.define do
  factory :agency do
    # Specify a starting ID number to avoid conflicts if we've added any data from agencies.yml
    sequence(:id, 1000)
    sequence(:name) { |n| "test-agency-#{n}" }
  end
end
