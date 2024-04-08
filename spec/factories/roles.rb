FactoryBot.define do
  factory :role do
    title { "MyString" }

    factory :ic_role do
      title { 'ic' }
    end

    factory :restricted_ic_role do
      title { 'restricted_ic' }
    end

    factory :login_eng_role do
      title { 'login_engineer' }
    end
  end
end
