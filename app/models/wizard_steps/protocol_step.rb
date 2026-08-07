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
  end
end
