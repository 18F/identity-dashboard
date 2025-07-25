class RedirectsValidator < IdentityValidations::IdentityValidator
  def validate(record)
    self.attribute ||= :redirect_uris
    uris = get_attribute(record)

    return if uris.blank?

    user = User.find record.user_id

    Array(uris).each do |uri_string|
      validating_uri = IdentityValidations::ValidatingURI.new(uri_string)
      record.errors.add(attribute, "#{uri_string} contains invalid wildcards(*)") if validating_uri.with_wildcards?
      record.errors.add(attribute, "#{uri_string} is not a valid URI") unless validating_uri.valid? || validating_uri.custom_scheme?

      changed_form_data = record.changes['wizard_form_data']
      attribute_unchanged = !changed_form_data || changed_form_data[0] && changed_form_data[0][attribute] == changed_form_data[1][attribute]
      # check if the attribute is changed
      if !attribute_unchanged
        # check if a nonadmin is using localhost on a prod_ready config
        if uri_string.match(/localhost:/) && record.production_ready? && !user.logingov_admin?
          record.errors.add(attribute, "'localhost' is not allowed on Production")
        end
      end
    end
  end
end
