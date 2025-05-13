class SamlCertsPresentValidator < ActiveModel::Validator
  def validate(record)
    if record.saml?
      if record.certs.blank?
        record.errors.add(:certs, "Certificate is required for SAML")
      end
    end
  end
end
