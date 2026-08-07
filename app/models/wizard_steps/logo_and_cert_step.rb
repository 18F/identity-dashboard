module WizardSteps
  # Public certificates and the partner logo for the service provider.
  class LogoAndCertStep
    def self.fields
      {
        certs: [],
        logo_name: '',
        remote_logo_key: '',
      }
    end

    def self.step_name
      'logo_and_cert'
    end
  end
end
