module WizardSteps
  # The service provider's issuer string.
  class IssuerStep
    def self.fields
      { issuer: '' }
    end

    def self.step_name
      'issuer'
    end
  end
end
