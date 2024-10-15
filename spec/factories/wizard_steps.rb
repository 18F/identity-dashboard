FactoryBot.define do
  factory :wizard_step do
    association :user, factory: :user
    step_name { WizardStep::STEPS[1..-1].sample }
    wizard_form_data { '{}' }
  end
end
