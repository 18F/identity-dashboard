class WizardStepPolicy < BasePolicy
  PARAMS = [
    :acs_url,
    :active,
    :agency_id,
    :allow_prompt_login,
    :approved,
    :assertion_consumer_logout_service_url,
    :block_encryption,
    :description,
    :friendly_name,
    :group_id,
    :ial,
    :default_aal,
    :identity_protocol,
    :issuer,
    :logo,
    :metadata_url,
    :return_to_sp_url,
    :failure_to_proof_url,
    :push_notification_url,
    :signed_response_message_requested,
    :sp_initiated_login_url,
    :logo_file,
    :app_name,
    :prod_config,
    { redirect_uris: [],
      attribute_bundle: [],
      help_text: {} },
  ].freeze

  def permitted_attributes
    return PARAMS unless IdentityConfig.store.prod_like_env
    return PARAMS if record == WizardStep # Not passed a specific record, passed the whole class

    existing_provider = record.existing_service_provider? && record.original_service_provider
    if existing_provider && ServiceProviderPolicy.new(user, existing_provider).ial_readonly?
      return PARAMS.reject { |param| param == :ial }
    end

    PARAMS
  end

  def destroy?
    IdentityConfig.store.service_config_wizard_enabled &&
      (user_has_login_admin_role? || record.user == user)
  end

  class Scope < BasePolicy::Scope
    def resolve
      scope.where(user:)
    end
  end
end
