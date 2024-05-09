class ServiceProvider < ApplicationRecord
  # Do not define validations in this model.
  # See https://github.com/18F/identity-validations
  include IdentityValidations::ServiceProviderValidation
  include ActionView::Helpers::SanitizeHelper

  has_paper_trail on: %i[create update destroy]

  attr_readonly :issuer
  attr_writer :issuer_department, :issuer_app

  belongs_to :user
  belongs_to :team, foreign_key: 'group_id', inverse_of: :service_providers

  has_one :agency, through: :team

  has_one_attached :logo_file
  validate :logo_is_less_than_mb
  validate :logo_file_mime_type
  validate :logo_file_ext_matches_type
  validate :certs_are_pems
  validate :validate_attribute_bundle

  enum block_encryption: { 'none' => 0, 'aes256-cbc' => 1 }, _suffix: 'encryption'
  enum identity_protocol: { openid_connect_private_key_jwt: 0, openid_connect_pkce: 2, saml: 1 }

  before_validation(on: %i[create update]) do
    self.attribute_bundle = attribute_bundle.reject(&:blank?) if attribute_bundle.present?
  end

  before_save :sanitize_help_text_content

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

  ALLOWED_HELP_TEXT_HTML_TAGS = %w[
    p
    br
    ol
    ul
    li
    a
    strong
    em
    b
  ].freeze

  def ial_friendly
    case ial
    when 1, nil
      I18n.t('service_provider_form.ial_option_1')
    when 2
      I18n.t('service_provider_form.ial_option_2')
    else
      ial.inspect
    end
  end

  def aal_friendly
    case default_aal
    when 1, nil
      I18n.t('service_provider_form.aal_option_default')
    when 2
      I18n.t('service_provider_form.aal_option_2')
    when 3
      I18n.t('service_provider_form.aal_option_3')
    else
      default_aal.inspect
    end
  end

  def help_text_opts
      options = {}
      friendly_name ||= '(Service Provider)'
      agency ||= '(Agency)'
      ['sign_in', 'sign_up', 'forgot_password'].each do |opt|
        options[opt] ||= {}
        I18n.t("service_provider_form.help_text", deep_interpolation: true, sp_name: friendly_name, agency: agency).each do |key, text|
          if(key.match? opt)
            options[opt][key] = text
          end
        end
      end

      return options
  end

  def custom_help_text

  end

  def self.possible_attributes
    Hash[*(ALLOWED_IAL1_ATTRIBUTES + ALLOWED_IAL2_ATTRIBUTES).collect { |v| [v, v] }.flatten]
  end

  def recently_approved?
    previous_changes.key?(:approved) && previous_changes[:approved].last == true
  end

  def redirect_uris=(uris)
    super uris.select(&:present?)
  end

  # @return [Array<ServiceProviderCertificate>]
  def certificates
    @certificates ||= Array(certs).map do |cert|
      ServiceProviderCertificate.new(OpenSSL::X509::Certificate.new(cert))
    rescue OpenSSL::X509::CertificateError
      null_certificate
    end
  end

  def remove_certificate(serial)
    certs&.delete_if do |cert|
      OpenSSL::X509::Certificate.new(cert).serial.to_s == serial.to_s
    rescue OpenSSL::X509::CertificateError
      nil
    end

    # clear memoization for #certificates
    @certificates = nil

    serial
  end

  def oidc?
    openid_connect_pkce? || openid_connect_private_key_jwt?
  end

  private

  def sanitize_help_text_content
    sections = [help_text['sign_in'], help_text['sign_up'], help_text['forgot_password']].compact
    sections.each { |section| sanitize_section(section) }
  end

  def sanitize_section(section)
    section.transform_values! do |translation|
      sanitize translation, tags: ALLOWED_HELP_TEXT_HTML_TAGS, attributes: %w[href target]
    end
  end

  # rubocop:disable Rails/TimeZone
  def null_certificate
    time = Time.new(0)
    OpenStruct.new(
      issuer: 'Null Certificate',
      not_before: time,
      not_after: time,
    )
  end
  # rubocop:enable Rails/TimeZone

  def logo_file_ext_matches_type
    return unless logo_file.attached?

    filename = logo_file.blob.filename.to_s

    file_ext = Regexp.new(
      /#{ServiceProviderHelper::SP_MIME_EXT_MAPPINGS[logo_file.content_type]}$/i,
    )

    return if filename.match(file_ext)

    errors.add(
      :logo_file,
      "The extension of the logo file you uploaded (#{filename}) does not match the content.",
    )
  end


  def logo_is_less_than_mb
    return unless logo_file.attached?

    if logo_file.blob.byte_size > 1.megabytes
      errors.add(:logo_file, 'Logo must be less than 1MB')
      logo_file = nil # rubocop:disable Lint/UselessAssignment
    end
  end

  def logo_file_mime_type
    return unless logo_file.attached?
    return if mime_type_valid?
    errors.add(:logo_file, "The file you uploaded (#{logo_file.filename}) is not a PNG or SVG")
    logo_file = nil # rubocop:disable Lint/UselessAssignment
  end

  def mime_type_valid?
    logo_file.content_type.in?(ServiceProviderHelper::SP_VALID_LOGO_MIME_TYPES)
  end

  def certs_are_pems
    Array(certs).each do |cert|
      next if cert.blank?

      if cert.include?('----BEGIN CERTIFICATE----')
        OpenSSL::X509::Certificate.new(cert)
      else
        errors.add(:certs, 'Certificate is a not PEM-encoded')
      end
    rescue OpenSSL::X509::CertificateError => err
      errors.add(:certs, err.message)
    end
  end

  def validate_attribute_bundle
    # attribute bundle should not be empty when saml and ial2 are selected
    if !attribute_bundle.present? && ial == 2 && identity_protocol == 'saml'
      errors.add(:attribute_bundle, 'Attribute bundle cannot be empty')
      return false
    end

    if attribute_bundle.present? && contains_invalid_attribute?
      errors.add(:attribute_bundle, 'Contains invalid attributes')
      return false
    end

    if ial == 1 && (attribute_bundle & ALLOWED_IAL2_ATTRIBUTES).present?
      errors.add(:attribute_bundle, 'Contains ial 2 attributes when ial 1 is selected')
    end
    true
  end

  def contains_invalid_attribute?
    possible_attributes = ALLOWED_IAL1_ATTRIBUTES + ALLOWED_IAL2_ATTRIBUTES
    attribute_bundle.any? { |att| !possible_attributes.include?(att) }
  end
end
