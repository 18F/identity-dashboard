module WizardSteps
  # Authentication settings: IAL, default AAL, and the requested attribute bundle.
  class AuthenticationStep
    def self.fields
      {
        attribute_bundle: [],
        default_aal: 0,
        ial: '1',
      }
    end

    def self.step_name
      'authentication'
    end
  end
end
