class CertsArePemsValidator < ActiveModel::Validator # :nodoc:
  def validate(record)
    Array(record.certs).each do |cert|
      next if cert.blank?

      if cert.include?('----BEGIN CERTIFICATE----')
        OpenSSL::X509::Certificate.new(cert)
      else
        record.errors.add(:certs, 'Certificate is a not PEM-encoded')
      end
    rescue OpenSSL::X509::CertificateError => err
      record.errors.add(:certs, err.message)
    end
  end
end
