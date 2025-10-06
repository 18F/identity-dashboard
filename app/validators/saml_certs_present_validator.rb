class SamlCertsPresentValidator < ActiveModel::Validator # :nodoc:
  def validate(record)
    return unless record.saml?
    return unless record.certs.blank?

    record.errors.add(:certs, I18n.t('service_provider_form.errors.certs.saml_no_cert'))
  end
end
