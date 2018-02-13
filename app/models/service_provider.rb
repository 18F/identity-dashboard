class ServiceProvider < ActiveRecord::Base
  attr_readonly :issuer

  belongs_to :user
  belongs_to :agency
  belongs_to :group

  enum block_encryption: { 'aes256-cbc' => 1 }
  enum identity_protocol: { openid_connect: 0, saml: 1 }

  validates :friendly_name, presence: true
  validates :issuer, presence: true, uniqueness: true
  validate :redirect_uris_are_parsable

  before_validation(on: %i(create update)) do
    self.attribute_bundle = attribute_bundle.reject(&:blank?) if attribute_bundle.present?
  end

  # rubocop:disable MethodLength
  def self.possible_attributes
    possible = %w(
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
    )
    Hash[*possible.collect { |v| [v, v] }.flatten]
  end
  # rubocop:ensable MethodLength

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
