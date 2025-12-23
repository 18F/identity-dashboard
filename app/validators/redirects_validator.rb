# Validates URI redirects partners propose for a ServiceProvider.
#
# Only `logingov_admin` is allowed to use `localhost` on a prod-ready config,
# unless that value is unchanged. The latter rule allows partners to add
# URIs while keeping an existing `localhost` that was applied by an admin.
class RedirectsValidator < IdentityValidations::IdentityValidator
  def validate(record)
    self.attribute ||= :redirect_uris
    uris = get_attribute(record)

    return if uris.blank?

    user = User.find record.user_id

    Array(uris).each do |uri_string|
      validating_uri = IdentityValidations::ValidatingURI.new(uri_string)
      if validating_uri.with_wildcards?
        record.errors.add(
          attribute,
          "#{uri_string} contains invalid wildcards(*)",
        )
      end
      unless validating_uri.valid? || validating_uri.custom_scheme?
        record.errors.add(
          attribute,
          "#{uri_string} is not a valid URI",
        )
      end

      changed_form_data = record.changes['wizard_form_data']
      attribute_unchanged = !changed_form_data || (
        changed_form_data[0] && changed_form_data[0][attribute] == changed_form_data[1][attribute]
      )
      # check if the attribute is changed
      # check if a nonadmin is using localhost on a prod_ready config
      if !attribute_unchanged && validating_uri.uri.host&.match(/(localhost|127\.0\.0)/) &&
         record.production_ready? && !user.logingov_admin?
        record.errors.add(attribute, "'localhost' is not allowed on Production")
      end
    end
  end
end
