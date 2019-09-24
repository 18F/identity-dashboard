class ServiceProvider < ApplicationRecord
  # Do not define validations in this model.
  # See https://github.com/18F/identity-validations
  include IdentityValidations::ServiceProviderValidation

  attr_readonly :issuer
  attr_writer :issuer_department, :issuer_app

  belongs_to :user
  belongs_to :group

  has_one :agency, through: :group

  enum block_encryption: { 'none' => 0, 'aes256-cbc' => 1 }, _suffix: 'encryption'
  enum identity_protocol: { openid_connect: 0, saml: 1 }

  before_validation(on: %i[create update]) do
    self.attribute_bundle = attribute_bundle.reject(&:blank?) if attribute_bundle.present?
  end

  def ial_friendly
    case ial
    when 1, nil
      'IAL1'
    when 2
      'IAL2'
    else
      ial.inspect
    end
  end

  # rubocop:disable MethodLength
  def self.possible_attributes
    possible = %w[
      email
      first_name
      middle_name
      last_name
      address1
      address2
      city
      state
      zipcode
      dob
      ssn
      phone
      x509_subject
      x509_presented
    ]
    Hash[*possible.collect { |v| [v, v] }.flatten]
  end
  # rubocop:enable MethodLength

  def recently_approved?
    previous_changes.key?(:approved) && previous_changes[:approved].last == true
  end

  def redirect_uris=(uris)
    super uris.select(&:present?)
  end

  def certificate
    @certificate ||= begin
                       if saml_client_cert
                         ServiceProviderCertificate.new saml_client_cert
                       else
                         null_certificate
                       end
                     rescue OpenSSL::X509::CertificateError
                       null_certificate
                     end
  end

  private

  # :reek:UtilityFunction
  # rubocop:disable Rails/TimeZone
  def null_certificate
    time = Time.new(0)
    OpenStruct.new(
      issuer: 'Null Certificate',
      not_before: time,
      not_after: time
    )
  end
  # rubocop:enable Rails/TimeZone
end
