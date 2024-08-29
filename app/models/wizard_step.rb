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
      group_id: 0,
      prod_config: false,
    }),
    authentication: WizardStep::Definition.new({
      attribute_bundle: [],
      default_aal: nil,
      identity_protocol: ServiceProvider.identity_protocols.keys.first,
      ial: 1,
      default_aal: 1,
      attribute_bundle: [],
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
  validates :group_id, presence: true, on: 'settings'
  validates :prod_config, presence: true, on: 'settings'
  validates :app_name, presence: true, on: 'settings'
  validates :friendly_name, presence: true, on: 'settings'
  validates :identity_protocol, presence: true, on: 'authorization'
  validates :ial, presence: true, on: 'authorization'
  validates :issuer, presence: true, on: 'issuer'
  validates :acs_url, presence: true, on: 'redirects', if: :identity_protocol == 'saml'
  validates :return_to_sp_url, presence: true, on: 'redirects', if: :identity_protocol == 'saml'

  def step_name=(new_name)
    raise ArgumentError, "Invalid WizardStep '#{new_name}'." unless STEP_DATA.has_key?(new_name)
    super
    self.data = enforce_valid_data(self.data)
  end

  def data=(new_data)
    super(enforce_valid_data(new_data))
  end

  def enforce_valid_data(new_data)
    return STEP_DATA[step_name].fields unless new_data.respond_to? :filter!
    new_data.filter! {|key, _v| STEP_DATA[step_name].has_field? key}
    STEP_DATA[step_name].fields.merge(new_data)
  end

  # SimpleForm uses this
  def self.reflect_on_association(relation)
    ServiceProvider.reflect_on_association(relation)
  end

  def self.block_encryptions
    ServiceProvider.block_encryptions
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

  def method_missing(name, *args, &block)
    if STEP_DATA.has_key?(step_name) && STEP_DATA[step_name].has_field?(name)
      data[name.to_s] ||= STEP_DATA[step_name].fields[name].dup
      data[name.to_s]
    else
      super
    end
  end

  private

  def null_certificate
    time = Time.zone.at(0)
    OpenStruct.new(
      issuer: 'Null Certificate',
      not_before: time,
      not_after: time,
    )
  end
end
