# The AttributeBundleValidator validates an attribute that is an array of strings.
# It requires that the record being validated has these as method or properties:
# * `ial`, of type Integer
# * `identity_protocol`, of type String
class AttributeBundleValidator < ActiveModel::EachValidator
  ALLOWED_IAL1_ATTRIBUTES = %w[
    email
    all_emails
    verified_at
    x509_subject
    x509_presented
  ].freeze

  ALLOWED_IAL2_ATTRIBUTES = %w[
    first_name
    last_name
    dob
    ssn
    address1
    address2
    city
    state
    zipcode
    phone
  ].freeze

  def self.possible_attributes
    Hash[*(ALLOWED_IAL1_ATTRIBUTES + ALLOWED_IAL2_ATTRIBUTES).collect { |v| [v, v] }.flatten]
  end

  def validate_each(record, attribute, attribute_bundle)
    # attribute bundle should not be empty when saml and ial2 are selected
    if attribute_bundle.blank? && record.ial == 2 && record.identity_protocol == 'saml'
      record.errors.add(:attribute_bundle, 'Attribute bundle cannot be empty')
      return false
    end

    if attribute_bundle.present? && contains_invalid_attribute?(attribute_bundle)
      record.errors.add(:attribute_bundle, 'Contains invalid attributes')
      return false
    end

    if ial == 1 && (attribute_bundle & ALLOWED_IAL2_ATTRIBUTES).present?
      record.errors.add(:attribute_bundle, 'Contains ial 2 attributes when ial 1 is selected')
    end
    true
  end

  private

  def contains_invalid_attribute?(attribute_bundle)
    possible_attributes = ALLOWED_IAL1_ATTRIBUTES + ALLOWED_IAL2_ATTRIBUTES
    attribute_bundle.any? { |att| !possible_attributes.include?(att) }
  end
end
