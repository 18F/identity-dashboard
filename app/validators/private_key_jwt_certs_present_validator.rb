# Validates for the presence of a public cert on OIDC private_key_jwt configurations
class PrivateKeyJwtCertsPresentValidator < ActiveModel::Validator
  def validate(record)
    return unless record.openid_connect_private_key_jwt?
    return if record.certs.present?

    record.errors.add(:certs, I18n.t('service_provider_form.errors.certs.private_key_jwt_no_cert'))
  end
end
