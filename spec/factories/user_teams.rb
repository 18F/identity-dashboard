FactoryBot.define do
  factory :user_team do
    user
    team

    trait :partner_admin do
      role_name { 'partner_admin' }
    end

    trait :partner_developer do
      role_name { 'partner_developer' }
    end

    trait :partner_readonly do
      role_name { 'partner_readonly' }
    end
  end
end
