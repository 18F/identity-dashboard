class WizardStep < ApplicationRecord
  class Definition
    attr_reader :fields
    def initialize(fields = {})
      @fields = fields.with_indifferent_access
    end

    def has_field?(name)
      fields.has_key?(name)
    end
  end

  DEFAULT_SAML_ENCRYPTION = ServiceProvider.block_encryptions.keys.last
  STEP_DATA = {
    intro: WizardStep::Definition.new,
    settings: WizardStep::Definition.new({
      app_name: '',
      description: '',
      friendly_name: '',
      group_id: nil,
      prod_config: false,
    }),
    protocol: WizardStep::Definition.new({
      identity_protocol: ServiceProvider.identity_protocols.keys.first,
    }),
    authentication: WizardStep::Definition.new({
      attribute_bundle: [],
      default_aal: nil,
      ial: '1',
    }),
    issuer: WizardStep::Definition.new({
      issuer: '',
    }),
    logo_and_cert: WizardStep::Definition.new({
      certs: [],
      logo_name: '',
      remote_logo_key: '',
    }),
    redirects: WizardStep::Definition.new({
      acs_url: '',
      assertion_consumer_logout_service_url: '',
      block_encryption: DEFAULT_SAML_ENCRYPTION,
      failure_to_proof_url: '',
      push_notification_url: '',
      redirect_uris: '',
      return_to_sp_url: '',
      signed_response_message_requested: true,
      sp_initiated_login_url: '',
    }),
    help_text: WizardStep::Definition.new({
      help_text: { sign_in: ''},
    }),
  }.with_indifferent_access.freeze

  STEPS = STEP_DATA.keys

  belongs_to :user
  enum step_name: STEPS.each_with_object(Hash.new) {|step, enum| enum[step] = step}.freeze
  has_one_attached :logo_file

  validates :step_name, presence: true

  validates :app_name, presence: true, on: 'settings'
  validates :group_id, presence: true, on: 'settings'
  validate :group_is_valid, on: 'settings'
 
  # This is in ServiceProvider, too, because Rails forms regularly put an initial, hidden, and
  # blank entry for various inputs so that a fallback blank exists if anything fails or gets skipped
  before_validation(on: 'authentication') do
    self.data['attribute_bundle'] = attribute_bundle.reject(&:blank?) if attribute_bundle.present?
  end

  validates_with AttributeBundleValidator, on: 'authentication'
  validates_with CertsArePemsValidator, on: 'logo_and_cert'
  validates_with LogoValidator, on: 'logo_and_cert'

  ### These should be more or less identical to IdentityValidations::ServiceProviderValidation
  # except for the step contexts
  validates :friendly_name, presence: true, on: 'settings'

  # We can't test uniqueness here with a built-in Rails vaildator because here
  # we have to search through the ServiceProviders table to find conflicts
  validates :issuer, presence: true, on: 'issuer'

  validates :issuer,
    format: { with: IdentityValidations::ServiceProviderValidation::ISSUER_FORMAT_REGEXP },
    on: 'issuer'
  validates :ial, inclusion: { in: [1, 2, '1', '2'] }, allow_nil: true

  validates_with IdentityValidations::AllowedRedirectsValidator, on: 'redirects'
  validates_with IdentityValidations::UriValidator,
    attribute: :failure_to_proof_url,
    on: 'redirects'
  validates_with IdentityValidations::UriValidator,
    attribute: :push_notification_url,
    on: 'redirects'
  validates_with IdentityValidations::UriValidator,
    attribute: :acs_url,
    on: 'redirects'
  validates_with IdentityValidations::UriValidator,
    attribute: :return_to_sp_url,
    on: 'redirects'
  validates_with IdentityValidations::UriValidator,
    attribute: :assertion_consumer_logout_service_url,
    on: 'redirects'

  validates_with IdentityValidations::CertsAreX509Validator, on: 'logo_and_cert'
  #
  ### end of validations copied from IdentityValidations::ServiceProviderValidation

  validate :issuer_service_provider_uniqueness, on: 'issuer'

  # SimpleForm uses this
  def self.reflect_on_association(relation)
    ServiceProvider.reflect_on_association(relation)
  end

  def self.block_encryptions
    ServiceProvider.block_encryptions
  end

  def self.all_step_data_for_user(user)
    WizardStepPolicy::Scope.new(user, self).resolve.reduce({}) do |memo, step|
      memo.merge(step.data)
    end
  end

  def step_name=(new_name)
    raise ArgumentError, "Invalid WizardStep '#{new_name}'." unless STEP_DATA.has_key?(new_name)
    super
    self.data = enforce_valid_data(self.data)
  end

  def data=(new_data)
    super(enforce_valid_data(new_data))
  end

  def valid?(*args)
    if args.blank? && step_name.present?
      super(step_name)
    else
      super
    end
  end

  # @return [Array<ServiceProviderCertificate>]
  # @throw [NameError] if this step doesn't have certs
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

  def attach_logo(logo_data)
    return unless step_name == 'logo_and_cert'
    self.logo_file = logo_data
    self.data = data.merge({
      logo_name: logo_file.filename.to_s,
      remote_logo_key: logo_file.key,
    })
  end

  def method_missing(name, *args, &block)
    if STEP_DATA.has_key?(step_name) && STEP_DATA[step_name].has_field?(name)
      data[name.to_s] ||= STEP_DATA[step_name].fields[name].dup
      data[name.to_s]
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    STEP_DATA.has_key?(step_name) && STEP_DATA[step_name].has_field?(method_name) || super
  end

  def auth_step
    return self if step_name == 'authentication'
    WizardStepPolicy::Scope.new(self.user, self.class).
      resolve.
      find_or_initialize_by(user: self.user, step_name: 'authentication')
  end

  def protocol_step
    return self if step_name == 'protocol'
    WizardStepPolicy::Scope.new(self.user, self.class).
      resolve.
      find_or_initialize_by(user: self.user, step_name: 'protocol')
  end

  def ial
    return data['ial'] if step_name == 'authentication'
    auth_step.ial
  end

  def identity_protocol
    return data['identity_protocol'] if step_name == 'protocol'
    protocol_step.identity_protocol
  end

  def saml?
    auth_step && protocol_step.identity_protocol == 'saml'
  end

  def saml_settings_present?
    ['acs_url', 'return_to_sp_url'].each do |attr|
      return true if !saml?

      errors.add(attr.to_sym, ' can\'t be blank') if data[attr].blank?
    end
    self.errors.empty?
  end

  def pending_or_current_logo_data
    return false unless step_name == 'logo_and_cert'
    return attachment_changes_string_buffer if attachment_changes['logo_file'].present?
    return logo_file.blob.download if logo_file.blob
  end

  private

  def enforce_valid_data(new_data)
    return STEP_DATA[step_name].fields unless new_data.respond_to? :filter!
    new_data.filter! {|key, _v| STEP_DATA[step_name].has_field? key}
    STEP_DATA[step_name].fields.merge(new_data)
  end

  def null_certificate
    time = Time.zone.at(0)
    OpenStruct.new(
      issuer: 'Null Certificate',
      not_before: time,
      not_after: time,
    )
  end

  def issuer_service_provider_uniqueness
    errors.add(:issuer, 'already in use') if ServiceProvider.where(issuer: issuer).any?
  end

  def group_is_valid
    errors.add(:group_id, :invalid) if Team.where(id: group_id).blank?
  end

  def attachment_changes_string_buffer
    if attachment_changes['logo_file'].attachable.respond_to?(:open)
      return File.read(attachment_changes['logo_file'].attachable.open)
    else
      return File.read(attachment_changes['logo_file'].attachable[:io])
    end
  end
end
