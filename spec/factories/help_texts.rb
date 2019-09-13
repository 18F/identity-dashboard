FactoryBot.define do
  factory :help_text do
    sign_in { { en: "<b>Some sign-in help text</b>" } }
    sign_up { { en: "<b>Some sign-up help text</b>" } }
    forgot_password { { en: "<b>Some forgot password help text</b>" } }
  end
end

