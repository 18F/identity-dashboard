FactoryBot.define do
  factory :auth_token do
    user
    token { 'MyString' }
  end
end
