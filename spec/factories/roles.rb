FactoryBot.define do
  factory :role do
    name { 'MyString' }
    friendly_name { 'My String' }
  end

  trait :logingov_admin do
    name { 'logingov_admin' }
    friendly_name { 'Login.gov Admin' }
  end

  trait :partner_admin do
    name { 'partner_admin' }
    friendly_name { 'Partner Admin' }
  end

  trait :partner_developer do
    name { 'partner_developer' }
    friendly_name { 'Partner Developer' }
  end

  trait :partner_readonly do
    name { 'partner_readonly' }
    friendly_name { 'Partner Readonly' }
  end
end
