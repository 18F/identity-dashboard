FactoryBot.define do
  factory :wizard_step do
    association :user
    step_name { WizardStep::STEPS[1..-1].sample }
    wizard_form_data { '{}' }
  end

  trait :production_ready do
    association :user
    step_name { 'settings' }
    wizard_form_data do
      '{
      "app_name" => "Production Configuration",
      "description" => "test with prod_config",
      "friendly_name" => "Prod Configuration",
      "group_id" => nil,
      "prod_config" => "true"
    }'
    end
  end
end
