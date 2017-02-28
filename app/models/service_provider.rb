class ServiceProvider < ActiveRecord::Base
  belongs_to :user
  belongs_to :agency
  belongs_to :organization

  enum block_encryption: { 'aes256-cbc' => 1 }

  validates :issuer, presence: true, uniqueness: true

  before_validation(on: [:create, :update]) do
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
