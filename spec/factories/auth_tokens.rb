FactoryBot.define do
  factory :auth_token do
    user { nil }
    token { 'MyString' }
  end
end
