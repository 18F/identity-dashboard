class RedirectsValidator < IdentityValidations::IdentityValidator # :nodoc:
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
      if !attribute_unchanged
        # check if a nonadmin is using localhost on a prod_ready config
        if validating_uri.uri.host&.match(/(localhost|127\.0\.0)/) &&
           record.production_ready? && !user.logingov_admin?
          record.errors.add(attribute, "'localhost' is not allowed on Production")
        end
      end
    end
  end
end
