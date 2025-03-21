require 'rails'

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

  def pending_or_current_logo_data
    return attachment_changes_string_buffer if attachment_changes['logo_file'].present?

    logo_file.blob.download if logo_file.blob
  end

  # ZENDESK_TICKET_POST_URL = 'https://logingov.zendesk.com/api/v2/requests.json'
  ZENDESK_TICKET_POST_URL = 'http://localhost:3002'
  ZENDESK_TICKET_FORM_ID = 5663417357332

  ZENDESK_TICKET_FIELD_FUNCTIONS = {
    20697165967508 => -> (record) { record.logo.present? },
    4418412738836 => -> (record) { record.agency.name.parameterize.underscore },
    4417948129556 => -> (record) { record.portal_url },
    23180053076628 => -> (record) { record.issuer },
    4417492827796 => -> (record) { record.app_name },
    4417494977300 => -> (record) { record.ial_zendesk },
    5064895580308 => -> (record) { record.description },
    4418367585684 => -> (record) { 'on' },
    4417169610388 => -> (record) { 'new_integration' },
  }

  ZENDESK_TICKET_FIELD_INFORMATION = {
    4417546214292 => { label: 'iaa_number',
      placeholder: 'LGABCFY210001-0001-0000',
      input_type: 'text' },
    4417940288916 => { label: 'application_url',
      placeholder: 'https://yourapp.gov/',
      input_type: 'text' },
    14323206118676 => { label: 'audience',
      placeholder: nil,
      input_type: 'select',
      options: [
        { label: 'Ganeral public', value: 'general_public' },
        { label: 'Federal civilian employee', value: 'federal_civilian_employee' },
        { label: 'Active duty U.S. military', value: 'active_duty_u.s._military' },
        { label: 'U.S. veteran', value: 'u.s._veteran' },
        { label: 'State or local employee', value: 'state_or_local_employee' },
        { label: 'Other', value: 'other' },
      ],
    },
    4417514509076 => { label: 'est_annual_reg',
      placeholder: 100000,
      input_type: 'text' },
    14323273767572 => { label: 'monthly_active_users',
      placeholder: 20000,
      input_type: 'text' },
    14326923502100 => { label: 'seasonality',
      placeholder: nil,
      input_type: 'text' },
    4417513940756 => { label: 'est_auths',
      placeholder: 50000,
      input_type: 'text' },
    4417512374548 => { label: 'launch_date',
      placeholder: nil,
      input_type: 'date' },
    4417547364628 => { label: 'billing_pocs',
      placeholder: 'First Last - Director, Department - first.last@agency.gov - (555) 555-5555',
      input_type: 'text' },
    4417948190868 => { label: 'pm_pocs',
      placeholder: 'First Last - Program Manager - first.last@agency.gov - (555) 555-5555',
      input_type: 'text' },
    4417940248340 => { label: 'tech_support_pocs',
      placeholder: 'First Last - Technical Lead - first.last@agency.gov - (555) 555-5555',
      input_type: 'text' },
    4975909708564 => { label: 'help_desk_contact_info',
      placeholder: '(555) 555-5555 - support@agency.gov',
      input_type: 'text' },
  }

  def build_zendesk_ticket(current_user, custom_fields)
    ticket_data = {
      request:  {
        requester: {
          name: "#{current_user.first_name} #{current_user.last_name}",
          email: current_user.email,
        },
        subject: "Deploy #{self.friendly_name} to Production",
        comment: {
          body: "Please deploy #{self.friendly_name} to the Login.gov Production Environment",
        },
        ticket_form_id: ZENDESK_TICKET_FORM_ID,
        custom_fields: custom_fields,
      },
    }
  end

  def portal_url
    "service_providers/#{self.id}"
  end

  def ial_zendesk
    case ial
    when 1, nil
      I18n.t('service_provider_form.zendesk_ticket.ial_option_1')
    when 2
      I18n.t('service_provider_form.zendesk_ticket.ial_option_2')
    else
      ial.inspect
    end
  end

  def create_ticket(ticket_data)
    headers = { 'Content-Type' => 'application/json' }

    conn = Faraday.new(url: ZENDESK_TICKET_POST_URL, headers: headers)

    resp = conn.post { |req| req.body = ticket_data.to_json }
    status_code = resp.status

    # if status_code
      resp.body
    # end
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
