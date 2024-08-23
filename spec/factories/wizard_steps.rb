FactoryBot.define do
  factory :wizard_step do
    user { nil }
    step_name { WizardStep::STEPS[1..-1].sample }
    data { '{}' }
  end
end
