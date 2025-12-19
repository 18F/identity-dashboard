# Validates URI redirects partners propose for a ServiceProvider.
#
# Only `logingov_admin` is allowed to use `localhost` on a prod-ready config,
# unless that value is unchanged. The latter rule allows partners to add
# URIs while keeping an existing `localhost` that was applied by an admin.
class RedirectsValidator < IdentityValidations::AllowedRedirectsValidator
  def validate(record)
    super
    self.attribute ||= :redirect_uris
    uris = get_attribute(record)

    return if uris.blank?

    Array(uris).each do |uri_string|
      # Only check if the attribute is changed
      check_non_admin_localhost(record, uri_string) unless attribute_unchanged(record, attribute)
    end
  end

  private

  def attribute_unchanged(record, attribute)
    changed_form_data = record.changes['wizard_form_data']
    !changed_form_data || (
      changed_form_data[0] && changed_form_data[0][attribute] == changed_form_data[1][attribute]
    )
  end

  def check_non_admin_localhost(record, uri_string)
    validating_uri = IdentityValidations::ValidatingURI.new(uri_string)
    user = User.find record.user_id

    # check if a nonadmin is using localhost on a prod_ready config
    if validating_uri.uri.host&.match(/(localhost|127\.0\.0)/) &&
       record.production_ready? && !user.logingov_admin?
      record.errors.add(attribute, "'localhost' is not allowed on Production")
    end
  end
end
