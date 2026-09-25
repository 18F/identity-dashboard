module WizardSteps
  # Selects the identity protocol (OIDC or SAML) for the service provider.
  class ProtocolStep
    def self.fields
      {
        identity_protocol: ServiceProvider.identity_protocols.keys.first,
      }
    end

    def self.step_name
      'protocol'
    end

    delegate :identity_protocol, to: :@wizard_step

    # @param wizard_step [WizardStep] the record this step reads and writes through
    def initialize(wizard_step)
      @wizard_step = wizard_step
    end

    def saml?
      identity_protocol == 'saml'
    end
  end
end
