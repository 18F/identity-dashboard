# Validates URI redirects partners propose for a ServiceProvider.
#
# Only `logingov_admin` is allowed to use `localhost` on a prod-ready config,
# unless that value is unchanged. The latter rule allows partners to add
# URIs while keeping an existing `localhost` that was applied by an admin.
class RedirectsValidator < IdentityValidations::AllowedRedirectsValidator
  VALID_HOST_PATTERN = /\A[a-z0-9\-_.]+\z/i

  def validate(record)
    super
    self.attribute ||= :redirect_uris
    @record = record
    uris = get_attribute(record)

    return if uris.blank?

    Array(uris).each do |uri_string|
      check_valid_host(uri_string)
    end

    # Only validate if the attribute is changing
    return if attribute_unchanged(attribute)

    Array(uris).each do |uri_string|
      check_nonadmin_localhost_redirect(uri_string)
    end
  end

  private

  def attribute_unchanged(attribute)
    if wizard?
      changed_form_data = @record.changes['wizard_form_data']
      attr_key = attribute.to_s

      !changed_form_data || (
        changed_form_data[0] && changed_form_data[0][attr_key] == changed_form_data[1][attr_key]
      )
    else
      !@record.changes[attribute]
    end
  end

  def check_valid_host(uri_string)
    validating_uri = IdentityValidations::ValidatingURI.new(uri_string)
    return unless validating_uri.parseable?

    host = validating_uri.uri.host
    return if host.blank?

    return if host.match?(VALID_HOST_PATTERN)

    @record.errors.add(attribute, "#{uri_string} has an invalid host")
  end

  def check_nonadmin_localhost_redirect(uri_string)
    validating_uri = IdentityValidations::ValidatingURI.new(uri_string)

    return unless validating_uri.parseable?

    uri = validating_uri.uri

    # check if a nonadmin is using localhost on a prod_ready config
    unless localhost_is_disallowed? && (uri.host&.match(/(localhost|127\.0\.0)/) ||
      uri.scheme == 'localhost')
      return
    end

    @record.errors.delete attribute if @record.errors[attribute].include? 'is invalid'
    @record.errors.add(attribute, "'localhost' is not allowed on Production")
  end

  def localhost_is_disallowed?
    return false unless @record.current_user_id

    user = User.find @record.current_user_id
    @record.production_ready? && !user.logingov_admin?
  end

  def wizard?
    @record.instance_of?(::WizardStep)
  end
end
