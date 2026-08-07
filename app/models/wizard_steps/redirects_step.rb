module WizardSteps
  # Redirect URIs and related URLs, plus SAML encryption settings.
  class RedirectsStep
    DEFAULT_SAML_ENCRYPTION = ServiceProvider.block_encryptions.keys.last

    def self.fields
      {
        acs_url: '',
        assertion_consumer_logout_service_url: '',
        block_encryption: DEFAULT_SAML_ENCRYPTION,
        failure_to_proof_url: '',
        post_idv_follow_up_url: nil,
        push_notification_url: '',
        redirect_uris: [],
        return_to_sp_url: '',
        signed_response_message_requested: true,
        sp_initiated_login_url: '',
      }
    end

    def self.step_name
      'redirects'
    end
  end
end
