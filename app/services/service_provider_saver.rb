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
    log.sp_errors(errors: errors.to_hash)
  end

  def clear_formatting
    string_attributes = %w[
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

    attributes.each do |k, v|
      v.try(:strip!) if string_attributes.include?(k)
    end

    redirect_uris&.each do |uri|
      uri.try(:strip!)
    end
  end
end
