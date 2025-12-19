# `ConfigSaver` contains a series of checks that we want to run every time a user creates or updates
#  a ServiceProvider config through the UI.
#
# This concern doesn't obviously belong to the model or a controller
module ConfigSaver
  STRING_ATTRIBUTES = %w[
    issuer
    friendly_name
    description
    metadata_url
    acs_url
    assertion_consumer_logout_service_url
    sp_initiated_login_url
    return_to_sp_url
    failure_to_proof_url
    push_notification_url
    app_name
  ]

  attr_reader :draft_config, :current_user, :errors

  def initialize(draft_config, current_user)
    @draft_config, @current_user = draft_config, current_user
  end

  def run
    clear_formatting
    draft_config.valid?
    draft_config.valid_saml_settings?
    draft_config.valid_prod_config?
    draft_config.valid_localhost_uris? if !current_user.logingov_admin?

    @errors = draft_config.errors
    service_provider.save! if @errors.none?
  end

  def clear_formatting
    draft.attributes.each do |k, v|
      v.try(:strip!) if STRING_ATTRIBUTES.include?(k)
    end

    service_provider.redirect_uris&.each do |uri|
      uri.try(:strip!)
    end
    service_provider
  end
end
