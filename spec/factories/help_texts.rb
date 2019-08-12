FactoryBot.define do
  factory :help_text do
    sign_in "<b>Some sign-in help text</b>"
    sign_up "<b>Some sign-up help text</b>"
    forgot_password "<b>Some forgot password help text</b>"
  end
end
