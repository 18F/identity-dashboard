FactoryBot.define do
  factory :team_membership do
    user
    team

    trait :logingov_admin do
      role_name { 'logingov_admin' }
    end

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
