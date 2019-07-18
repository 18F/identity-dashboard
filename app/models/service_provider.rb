class ServiceProvider < ApplicationRecord
  # Note: We no longer have strong validation of the issuer string. We used to
  #         require that the issuer matched this format:
  #         'urn:gov:gsa:<protocol>:2.0.profiles:sp:sso:<agency>:<app name>'
  #         However, it was too restrictive for many COTS applications. Now,
  #         we just enforce uniqueness, without whitespace.

  ISSUER_FORMAT_REGEXP = /\A[\S]+\z/

  attr_readonly :issuer
  attr_writer :issuer_department, :issuer_app

  belongs_to :user
  belongs_to :agency
  belongs_to :group

  enum block_encryption: { 'none' => 0, 'aes256-cbc' => 1 }, _suffix: 'encryption'
  enum identity_protocol: { openid_connect: 0, saml: 1 }

  validates :friendly_name, presence: true
  validates :issuer, presence: true, uniqueness: true
  validates :issuer, format: { with: ISSUER_FORMAT_REGEXP }, on: :create

  validate :redirect_uris_are_parsable
  validate :failure_to_proof_url_is_parsable

  validate :saml_client_cert_is_x509_if_present

  validates :ial, inclusion: { in: [1, 2] }, allow_nil: true

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

  private

  def redirect_uris_are_parsable
    return if redirect_uris.blank?

    redirect_uris.each do |uri|
      next if uri_valid?(uri)
      errors.add(:redirect_uris, :invalid)
      break
    end
  end

  def uri_valid?(uri)
    parsed_uri = URI.parse(uri)
    parsed_uri.scheme.present? && parsed_uri.host.present?
  rescue URI::BadURIError, URI::InvalidURIError
    false
  end

  def failure_to_proof_url_is_parsable
    return if failure_to_proof_url.blank?

    unless uri_valid?(failure_to_proof_url)
      errors.add(:failure_to_proof_url, :invalid)
    end
  end

  def saml_client_cert_is_x509_if_present
    return if saml_client_cert.blank?

    begin
      OpenSSL::X509::Certificate.new(saml_client_cert)
    rescue OpenSSL::X509::CertificateError
      errors.add(:saml_client_cert, :invalid)
    end
  end
end
