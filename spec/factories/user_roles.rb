FactoryBot.define do
  factory :user_role do
    user { nil }
    role { Role.find_or_create_by(title: 'restricted_ic')}

    factory :admin_user_role do
      role { Role.find_or_create_by(title: 'login_engineer')}
    end

    factory :ic_user_role do
      role { Role.find_or_create_by(title: 'ic')}
    end
  end
end
