FactoryBot.define do
  factory :wizard_step do
    association :user, factory: :user
    step_name { WizardStep::STEPS[1..-1].sample }
    wizard_form_data { '{}' }
  end

  trait :production_ready do
    association :user, factory: :user
    step_name { 'settings' }
    wizard_form_data do
      '{
      "app_name" => "Production App",
      "description" => "test with prod_config",
      "friendly_name" => "Prod App",
      "group_id" => nil,
      "prod_config" => "true"
    }'
    end
  end
end
