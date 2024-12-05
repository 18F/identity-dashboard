FactoryBot.define do
  factory :user_team do
    user
    team

    trait :partner_admin do
      role_name { 'Partner Admin'}
    end

    trait :partner_developer do
      role_name { 'Partner Developer' }
    end

    trait :partner_readonly do
      role_name { 'Partner Readonly' }
    end
  end
end
