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

  # A list of steps and their attributes
  #
  # Generally, you won't want to access this list directly outside of the WizardStep class itself.
  # This list contains fields that should get preserved when editing an existing config
  # but we do not want to show up in the UI. This constant is an implementation detail.
  #
  # Instead, use `STEP` constant to get a list of the non-hidden steps or
  # use a method in this class that encapsulates the implementation.
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
      default_aal: 0,
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
      redirect_uris: [],
      return_to_sp_url: '',
      signed_response_message_requested: true,
      sp_initiated_login_url: '',
    }),
    help_text: WizardStep::Definition.new({
      help_text: { sign_in: '' },
    }),
    # Unless we are editing an existing config, this extra step should not get created.
    hidden: WizardStep::Definition.new({
      active: false,
      agency_id: nil,
      allow_prompt_login: false,
      approved: false,
      email_nameid_format_allowed: nil,
      metadata_url: nil,
      service_provider_id: nil,
      service_provider_user_id: nil,
      post_idv_follow_up_url: nil,
    }),
  }.with_indifferent_access.freeze

  STEPS = (STEP_DATA.keys - ['hidden']).freeze

  # A reverse lookup, answers the question:
  #     Given an attribute, which step does it belong to?
  ATTRIBUTE_STEP_LOOKUP = STEP_DATA.
    each_with_object({}) do |(step_name, definition), hash|
      definition.fields.keys.each do |field_name|
        hash[field_name] = step_name
      end
    end.
  freeze

  belongs_to :user

  step_enum_values = STEP_DATA.keys.each_with_object(Hash.new) do |step, enum|
    enum[step] = step
  end
  # We want the hidden step to be a valid step name to save in the database
  # so we can track attributes even if they should not show up in the UI
  enum :step_name, step_enum_values

  has_one_attached :logo_file

  validates :step_name, presence: true

  validates :app_name, presence: true, on: 'settings'
  validates :group_id, presence: true, on: 'settings'
  validate :group_is_valid, on: 'settings'

  # This is in ServiceProvider, too, because Rails forms regularly put an initial, hidden, and
  # blank entry for various inputs so that a fallback blank exists if anything fails or gets skipped
  before_validation(on: 'authentication') do
    if attribute_bundle.present?
      self.wizard_form_data['attribute_bundle'] = attribute_bundle.reject(&:blank?)
    end
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
  validate :failure_to_proof_url_for_idv, on: 'redirects'

  # SimpleForm uses this
  def self.reflect_on_association(relation)
    ServiceProvider.reflect_on_association(relation)
  end

  def self.block_encryptions
    ServiceProvider.block_encryptions
  end

  def self.all_step_data_for_user(user)
    # This intentionally should get all steps including the "hidden" step if it exists
    WizardStepPolicy::Scope.new(user, self).resolve.reduce({}) do |memo, step|
      memo.merge(step.wizard_form_data)
    end
  end

  def self.service_provider_to_wizard_attribute_map
    @@service_provider_to_wizard_attribute_map ||= ServiceProvider.
      attribute_names.
      each_with_object({}) do |attribute_name, hash|
        next if ['created_at', 'updated_at'].include? attribute_name

        hash[attribute_name] = case attribute_name
          when 'logo'
            'logo_name'
          when 'user_id'
            'service_provider_user_id'
          when 'id'
            'service_provider_id'
          else
            attribute_name
          end
      end
  end

  def self.steps_from_service_provider(service_provider, user)
    steps = STEP_DATA.keys.each_with_object(Hash.new) do |step_name, hash|
      hash[step_name] = find_or_initialize_by(step_name:, user:)
    end

    service_provider.attribute_names.each do |source_attr_name|
      next unless service_provider_to_wizard_attribute_map.has_key?(source_attr_name)

      wizard_attribute_name = service_provider_to_wizard_attribute_map[source_attr_name]
      step_name = ATTRIBUTE_STEP_LOOKUP[wizard_attribute_name]
      next unless step_name # This is an attribute we're willing to discard

      steps[step_name].wizard_form_data[wizard_attribute_name] =
        service_provider.attributes[source_attr_name]
    end
    steps.values
  end

  def step_name=(new_name)
    raise ArgumentError, "Invalid WizardStep '#{new_name}'." unless STEP_DATA.has_key?(new_name)

    super
    self.wizard_form_data = enforce_valid_data(self.wizard_form_data)
  end

  def wizard_form_data=(new_data)
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
    certs.delete_if do |cert|
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
    self.wizard_form_data = wizard_form_data.merge({
      logo_name: logo_file.filename.to_s,
      remote_logo_key: logo_file.key,
    })
  end

  def method_missing(name, *args, &block)
    if STEP_DATA.has_key?(step_name) && STEP_DATA[step_name].has_field?(name)
      wizard_form_data[name.to_s] ||= STEP_DATA[step_name].fields[name].dup
      wizard_form_data[name.to_s]
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    STEP_DATA.has_key?(step_name) && STEP_DATA[step_name].has_field?(method_name) || super
  end

  def get_step(step_to_find)
    return self if step_name == step_to_find

    WizardStepPolicy::Scope.new(self.user, self.class).
      resolve.
      find_or_initialize_by(user: self.user, step_name: step_to_find)
  end

  def ial
    return wizard_form_data['ial'] if step_name == 'authentication'

    get_step('authentication').ial
  end

  def saml?
    get_step('protocol').identity_protocol == 'saml'
  end

  def saml_settings_present?
    ['acs_url', 'return_to_sp_url'].each do |attr|
      return true if !saml?

      errors.add(attr.to_sym, ' can\'t be blank') if wizard_form_data[attr].blank?
    end
    self.errors.empty?
  end

  def pending_or_current_logo_data
    return false unless step_name == 'logo_and_cert'
    return attachment_changes_string_buffer if attachment_changes['logo_file'].present?

    logo_file.blob.download if logo_file.blob
  end

  def existing_service_provider?
    !!original_service_provider
  end

  def original_service_provider
    id = WizardStep.find_by(step_name: 'hidden', user: user)&.service_provider_id
    id && ServiceProviderPolicy::Scope.new(user, ServiceProvider).resolve.find(id)
  end

  private

  def enforce_valid_data(new_data)
    return STEP_DATA[step_name].fields unless new_data.respond_to? :filter!

    new_data.filter! { |key, _v| STEP_DATA[step_name].has_field? key }
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
    return if existing_service_provider? && original_service_provider.issuer == issuer

    errors.add(:issuer, 'already in use') if ServiceProvider.where(issuer:).any?
  end

  def failure_to_proof_url_for_idv
    using_idv = ial.to_i > 1
    return if !using_idv

    errors.add(:failure_to_proof_url, :empty) if failure_to_proof_url.blank?
  end

  def group_is_valid
    errors.add(:group_id, :invalid) if Team.where(id: group_id).blank?
  end

  def attachment_changes_string_buffer
    attachable = attachment_changes['logo_file'].attachable
    return attachable.download if attachable.respond_to?(:download)

    File.read(attachable.open)
  end
end
