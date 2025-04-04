# The AttributeBundleValidator validates an attribute that is an array of strings.
# It requires that the record being validated has these as method or properties:
# * `ial`, of type Integer
# * `saml?`, of type Boolean
# * `attribute_bundle`, of type Array<String>
class AttributeBundleValidator < ActiveModel::Validator
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

  ALL_ATTRIBUTES = Hash[
    *(ALLOWED_IAL1_ATTRIBUTES + ALLOWED_IAL2_ATTRIBUTES).
      collect { |v| [v, v] }.
      flatten
  ].freeze

  def validate(record)
    # attribute bundle should not be empty when saml and ial2 are selected
    if record.attribute_bundle.blank? &&
       [2, '2'].include?(record.ial) &&
       record.saml?

      record.errors.add(:attribute_bundle, 'Attribute bundle cannot be empty')
      return false
    end

    if record.attribute_bundle.present? && contains_invalid_attribute?(record.attribute_bundle)
      record.errors.add(:attribute_bundle, 'Contains invalid attributes')
      return false
    end

    if [1, '1'].include?(record.ial) && (record.attribute_bundle & ALLOWED_IAL2_ATTRIBUTES).present?
      record.errors.add(:attribute_bundle, 'Contains ial 2 attributes when ial 1 is selected')
    end
    true
  end

  private

  def contains_invalid_attribute?(attribute_bundle)
    attribute_bundle.any? { |att| !ALL_ATTRIBUTES.keys.include?(att) }
  end
end
