class ServiceProvider < ApplicationRecord
  # Note: We've temporarily disabled validation of the issuer. Validations have
  # been commented out.

  ISSUER_FORMAT_REGEXP = /
    \Aurn:gov:gsa:(?<protocol>SAML:2\.0|openidconnect)
    \.profiles:sp:sso:(?<department>.+):(?<app>.+)\z
  /x

  attr_readonly :issuer
  attr_writer :issuer_department, :issuer_app

  belongs_to :user
  belongs_to :agency
  belongs_to :group

  enum block_encryption: { 'aes256-cbc' => 1 }
  enum identity_protocol: { openid_connect: 0, saml: 1 }

  validates :friendly_name, presence: true
  validates :issuer, presence: true, uniqueness: true
  # validates :issuer, format: { with: ISSUER_FORMAT_REGEXP }, on: :create
  # validates :issuer_department, presence: true, on: :create
  # validates :issuer_app, presence: true, on: :create
  # validates :agency
  validate :redirect_uris_are_parsable

  before_validation(on: %i[create update]) do
    self.attribute_bundle = attribute_bundle.reject(&:blank?) if attribute_bundle.present?
  end
  # before_validation :build_issuer, on: :create

  def issuer_department
    @issuer_department || ServiceProviderIssuerParser.new(issuer).parse[:department]
  end

  def issuer_app
    @issuer_app || ServiceProviderIssuerParser.new(issuer).parse[:app]
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

  def build_issuer
    return unless issuer_department && issuer_app
    self.issuer = ServiceProviderIssuerBuilder.new(self).build_issuer
  end

  def redirect_uris_are_parsable
    return if redirect_uris.blank?

    redirect_uris.each do |uri|
      next if redirect_uri_valid?(uri)
      errors.add(:redirect_uris, :invalid)
      break
    end
  end

  def redirect_uri_valid?(redirect_uri)
    parsed_uri = URI.parse(redirect_uri)
    parsed_uri.scheme.present? || parsed_uri.host.present?
  rescue URI::BadURIError, URI::InvalidURIError
    false
  end
end
