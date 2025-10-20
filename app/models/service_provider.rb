require 'rails'
require 'uri'

# The ServiceProvider, sometimes called "config" or "app", is the central
# object of the Portal. These configurations are required in order to
# create a Login.gov integration.
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
  validates_with LogoValidator
  validates_with CertsArePemsValidator
  validates_with AttributeBundleValidator

  STATUSES = %w[pending live rejected moved_to_prod].freeze

  enum :status, Hash[STATUSES.zip STATUSES], default: 'pending'
  enum :block_encryption, {
    'none' => 0,
    'aes256-gcm' => 2,
    'aes256-cbc' => 1,
  }, suffix: 'encryption'
  enum :identity_protocol, { openid_connect_private_key_jwt: 0, openid_connect_pkce: 2, saml: 1 }

  before_validation(on: %i[create update]) do
    self.attribute_bundle = attribute_bundle.reject(&:blank?) if attribute_bundle.present?
  end

  before_save :sanitize_help_text_content
  after_save ->(record) { record.status = 'live' },
    unless: -> { IdentityConfig.store.prod_like_env }

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

  def self.possible_attributes
    AttributeBundleValidator::ALL_ATTRIBUTES
  end

  def recently_approved?
    previous_changes.key?(:approved) && previous_changes[:approved].last == true
  end

  def redirect_uris=(uris)
    super uris&.select(&:present?)
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

  def production_ready?
    attributes['prod_config']
  end

  def prod_localhost?(input)
    return false if !production_ready?

    Array(self[input]).any? do |value|
      URI(value).host&.match?(/(localhost|127\.0\.0)/)
    end
  end

  def oidc?
    openid_connect_pkce? || openid_connect_private_key_jwt?
  end

  def saml?
    attributes['identity_protocol'] == 'saml'
  end

  def valid_saml_settings?
    saml_settings = %w[
      acs_url
      return_to_sp_url
    ]

    saml_settings.each do |attr|
      if !saml?
        attributes[attr] = ''
      elsif attributes[attr].blank?
        errors.add(attr.to_sym, ' can\'t be blank')
      end
    end
    errors.empty?
  end

  def valid_prod_config?
    return unless IdentityConfig.store.prod_like_env && !production_ready?

    errors.add(:prod_config, 'can\t be a sandbox config')
  end

  # in the case of Long Form, :long_form should be passed in for extra checks.
  def valid_localhost_uris?
    saml_settings = %w[
      acs_url
      assertion_consumer_logout_service_url
      sp_initiated_login_url
      return_to_sp_url
      push_notification_url
      failure_to_proof_url
      redirect_uris
    ]
    oidc_settings = %w[
      push_notification_url
      failure_to_proof_url
      redirect_uris
    ]

    settings = saml? ? saml_settings : oidc_settings
    prod_config_changed = self.changes['prod_config']
    changed_to_prod = prod_config_changed && prod_config_changed[1]
    settings.each do |attr|
      changes = self.changes[attr]
      if prod_localhost?(attr)
        if changed_to_prod && errors.where(:prod_config).empty?
          errors.add(:prod_config, 'can\'t set to Production Ready with localhost URLs')
        end
        if changes && changes[0] != changes[1]
          errors.add(attr.to_sym, ' can\'t use "localhost" on Production')
        end
      end
    end
  end

  def pending_or_current_logo_data
    return attachment_changes_string_buffer if attachment_changes['logo_file'].present?

    logo_file&.blob&.download
  end

  def compile_errors
    error_msg =
      "<p class='usa-alert__text'>Error(s) found in these fields:</p><ul class='usa-list'>"
    errors.each do |err|
      if err.attribute == :prod_config && production_ready?
        error_msg += '<li>Portal Config cannot be Production with localhost URLs</li>'
      else
        error_msg += "<li>#{I18n.t("service_provider_form.title.#{err.attribute}")}</li>"
      end
    end
    # this prevents cookie size error, it is an estimate
    if error_msg.bytesize < 350
      "#{error_msg}</ul>"
    else
      'Please fix errors on multiple fields.'
    end
  end

  private

  def attachment_changes_string_buffer
    attachable = attachment_changes['logo_file'].attachable
    return attachable.download if attachable.respond_to?(:download)

    File.read(attachable.open)
  end

  def sanitize_help_text_content
    sections = [help_text['sign_in'], help_text['sign_up'], help_text['forgot_password']]
    sections.select(&:present?).each { |section| sanitize_section(section) }
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
end
