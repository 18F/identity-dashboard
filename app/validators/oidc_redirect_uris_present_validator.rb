# Validates for the presence of redirect URIs on OIDC configurations
class OidcRedirectUrisPresentValidator < ActiveModel::Validator
  def validate(record)
    return unless record.oidc?
    return if record.redirect_uris.present?

    record.errors.add(:redirect_uris, :blank)
  end
end
