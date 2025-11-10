FactoryBot.define do
  factory :role do
    name { 'MyString' }
  end

  trait :logingov_admin do
    name { 'logingov_admin' }
  end

  trait :partner_admin do
    name { 'partner_admin' }
  end

  trait :partner_developer do
    name { 'partner_developer' }
  end

  trait :partner_readonly do
    name { 'partner_readonly' }
  end
end
