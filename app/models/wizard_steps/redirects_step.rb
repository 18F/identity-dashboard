module WizardSteps
  # Redirect URIs and related URLs, plus SAML encryption settings.
  class RedirectsStep
    include ActiveModel::Validations

    DEFAULT_SAML_ENCRYPTION = ServiceProvider.block_encryptions.keys.last
    REDIRECT_URL_FIELDS = %i[
      acs_url
      assertion_consumer_logout_service_url
      failure_to_proof_url
      push_notification_url
      redirect_uris
      return_to_sp_url
      sp_initiated_login_url
    ].freeze

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

    # delegates to the wizard_step model object
    delegate(
      *REDIRECT_URL_FIELDS,
      :changes,
      :current_user_id,
      :production_ready?,
      :saml?,
      :wizard_form_data,
      to: :@wizard_step,
    )

    REDIRECT_URL_FIELDS.each do |attribute|
      validates_with RedirectsValidator, attribute:, wizard: true
    end

    validate :failure_to_proof_url_for_idv
    validate :saml_settings_present

    # @param wizard_step [WizardStep] the record this step reads and writes through
    def initialize(wizard_step)
      @wizard_step = wizard_step
    end

    def failure_to_proof_url_for_idv
      return unless @wizard_step.using_idv?

      errors.add(:failure_to_proof_url, :empty) if failure_to_proof_url.blank?
    end

    def saml_settings_present
      return unless saml?

      ['acs_url', 'return_to_sp_url'].each do |attr|
        errors.add(attr.to_sym, ' can\'t be blank') if wizard_form_data[attr].blank?
      end
    end
  end
end
