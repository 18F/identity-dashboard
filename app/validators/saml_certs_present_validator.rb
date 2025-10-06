# Validator for SAML certificates
class SamlCertsPresentValidator < ActiveModel::Validator
  def validate(record)
    return unless record.saml?
    return unless record.certs.blank?

    record.errors.add(:certs, I18n.t('service_provider_form.errors.certs.saml_no_cert'))
  end
end
