require 'delegate'
# A procedural class that encapsulates common steps necessary when updating a `ServiceProvider`
# through the web UI.
#
# In the future, we may want add features here such as
# * a method to return messages the controllers display as flash messages
# * a method that accepts a block and conditionally evaluates whether an error occurred or not
class ServiceProviderForm < SimpleDelegator
  include ActionView::Helpers::TranslationHelper

  attr_reader :current_user, :log

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

  URI_ATTRIBUTES = %i[
    redirect_uris
    failure_to_proof_url
    push_notification_url
    acs_url
    sp_initiated_login_url
    return_to_sp_url
    assertion_consumer_logout_service_url
  ].freeze

  def initialize(service_provider, current_user, log)
    @current_user, @log = current_user, log
    super(service_provider)
  end

  def validate_and_save
    clear_formatting

    valid?
    valid_saml_settings?
    valid_sandbox_config?
    valid_prod_config? unless current_user.logingov_admin?
    sanitize_error_messages!

    log_errors && return if errors.any?

    @saved = save
  end

  def saved?
    @saved
  end

  def compile_errors
    error_msg =
      "<p class='usa-alert__text'>Error(s) found in these fields:</p><ul class='usa-list'>"
    error_msg += translate_errors.join

    # this prevents cookie size error, it is an estimate
    if error_msg.bytesize < 350
      "#{error_msg}</ul>"
    else
      'Please fix errors on multiple fields.'
    end
  end

  private

  def translate_errors
    errors.map(&:attribute).uniq.map do |attribute|
      if production_ready?
        if attribute == :prod_config
          '<li>Portal Configuration cannot be Production with localhost URLs</li>'
        elsif URI_ATTRIBUTES.include? attribute
          "<li>#{I18n.t("service_provider_form.title.#{attribute}")}: #{errors[attribute][0]}</li>"
        end
      else
        "<li>#{I18n.t("service_provider_form.title.#{attribute}")}</li>"
      end
    end
  end

  def log_errors
    log.sp_errors(errors: errors.to_hash)
  end

  # Some errors inherited from IdentityValidations::ServiceProviderValidation may attempt
  # to include an entire invalid attached file (e.g. raw bytes of an uploaded cert) verbatim
  # in the message. Truncate long errors down to the message at the end, and fix up invalid
  # encodings. This keeps messages legible and prevents exceptions when logging or rendering
  # the error, e.g. in JSON encoding or ERB template rendering.
  def sanitize_error_messages!
    errors.attribute_names.each do |attribute|
      messages = errors[attribute].map { |message| sanitize_error_message(message) }

      next if messages == errors[attribute]

      errors.delete(attribute)
      messages.each { |message| errors.add(attribute, message) }
    end
  end

  def sanitize_error_message(message)
    message = message.last(70) if message.length > 256
    message.valid_encoding? ? message : message.dup.force_encoding('UTF-8').scrub
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
