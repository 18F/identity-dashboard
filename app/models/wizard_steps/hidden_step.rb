module WizardSteps
  # A pseudo-step that is not shown in the UI. It preserves service provider
  # attributes that must survive an edit round-trip but should not be editable
  # in the Guided Flow.
  # This step is not created in the creation flow.
  # It is intentionally excluded from WizardStep::STEPS.
  class HiddenStep
    def self.fields
      {
        active: false,
        agency_id: nil,
        allow_prompt_login: false,
        approved: false,
        email_nameid_format_allowed: nil,
        metadata_url: nil,
        service_provider_id: nil,
        service_provider_user_id: nil,
      }
    end

    def self.step_name
      'hidden'
    end
  end
end
