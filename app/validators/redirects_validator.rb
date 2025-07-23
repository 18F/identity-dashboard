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
      if uri_string.match(/localhost:/)
        record.errors.add(attribute, "'localhost' is not allowed on Production") unless user.logingov_admin?
      end
    end
  end
end
