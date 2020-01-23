FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "department_name-#{n}" }
    sequence(:description) { |n| "description-#{n}" }
    association :agency, factory: :agency
  end
end
