class ServiceProvider < ActiveRecord::Base
  belongs_to :user
  belongs_to :agency
  belongs_to :user_group

  enum block_encryption: { 'aes256-cbc' => 1 }
  enum identity_protocol: { openid_connect: 0, saml: 1 }

  validates :issuer, presence: true, uniqueness: true
  validates :agency, presence: true

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
end
