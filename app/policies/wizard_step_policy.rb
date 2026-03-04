# Permission policy for WizardStep (steps of Guided Flow)
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
    :post_idv_follow_up_url,
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

    params = PARAMS.dup
    if existing_config && ServiceProviderPolicy.new(user, existing_config).ial_readonly?
      params.delete(:ial)
    end
    params.delete(:post_idv_follow_up_url) unless edit_idv_follow_up?

    params
  end

  def destroy?
    user_has_login_admin_role? || record.user == user
  end

  def edit_idv_follow_up?
    return true if user_has_login_admin_role?

    existing_config && ServiceProviderPolicy.new(user, existing_config).edit_idv_follow_up?
  end

  # WizardStep policy scope
  class Scope < BasePolicy::Scope
    def resolve
      scope.where(user:)
    end
  end

  private

  def existing_config
    record.existing_service_provider? && record.original_service_provider
  end
end
