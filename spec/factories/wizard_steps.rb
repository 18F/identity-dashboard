FactoryBot.define do
  factory :wizard_step do
    user { nil }
    step { "settings" }
    data { "{}" }
  end
end
