require 'delegate'
# A procedural class that encapsulates common steps necessary when updating a `ServiceProvider`
# through the web UI.
#
# In the future, we may want add features here such as
# * a method to return messages the controllers display as flash messages
# * a method that accepts a block and conditionally evaluates whether an error occurred or not
class ServiceProviderSaver < SimpleDelegator
  attr_reader :controller

  delegate :current_user, :log, to: :controller

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
  ].freeze

  def initialize(service_provider, controller)
    @controller = controller
    super(service_provider)
  end

  def validate_and_save
    clear_formatting

    valid?
    valid_saml_settings?
    valid_prod_config?
    valid_localhost_uris? unless current_user.logingov_admin?

    log_errors if errors.any?
  end

  private

  def log_errors
    sanitized_errors = errors.to_hash

    # Some errors inherited from IdentityValidations::ServiceProviderValidation may attempt
    # to include an entire invalid attached file.
    # Truncate long errors to the message at the end. This keeps the message legible and prevents
    # exceptions getting thrown when trying to encode an entire file the log message.
    sanitized_errors.keys.each do |key|
      sanitized_errors[key] = sanitized_errors[key].map do |error_string|
        error_string.length > 256 ? error_string.last(70) : error_string
      end
    end

    log.sp_errors(errors: sanitized_errors)
  end

  def clear_formatting
    attributes.each do |k, v|
      v.try(:strip!) if STRING_ATTRIBUTES.include?(k)
    end

    redirect_uris&.each do |uri|
      uri.try(:strip!)
    end
  end
end
