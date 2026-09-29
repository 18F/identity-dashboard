# A WizardStep is one page of the Guided Flow for creating or editing
# a ServiceProvider.
class WizardStep < ApplicationRecord
  # Definition of individual WizardStep
  class Definition
    attr_reader :fields

    def initialize(fields = {})
      @fields = fields.with_indifferent_access
    end

    def has_field?(name)
      fields.has_key?(name)
    end
  end

  # A list of steps and their attributes.
  #
  # Generally, you won't want to access this list directly outside of the WizardStep class itself.
  # This list contains fields that should get preserved when editing an existing config
  # but we do not want to show up in the UI. This constant is an implementation detail.
  #
  # Instead, use `STEPS` constant to get a list of the non-hidden steps or
  # use a method in this class that encapsulates the implementation.
  STEP_DATA = WizardSteps::Registry.step_classes.each_with_object({}) do |step_class, hash|
    hash[step_class.step_name] = WizardStep::Definition.new(step_class.fields)
  end.with_indifferent_access.freeze

  STEPS = (STEP_DATA.keys - [WizardSteps::Registry::HIDDEN_STEP_NAME]).freeze

  # A reverse lookup, answers the question:
  #     Given an attribute, which step does it belong to?
  ATTRIBUTE_STEP_LOOKUP = STEP_DATA
    .each_with_object({}) do |(step_name, definition), hash|
      definition.fields.keys.each do |field_name|
        hash[field_name] = step_name
      end
    end
    .freeze

  attr_accessor :current_user_id

  belongs_to :user

  step_enum_values = STEP_DATA.keys.each_with_object({}) do |step, enum|
    enum[step] = step
  end
  # We want the hidden step to be a valid step name to save in the database
  # so we can track attributes even if they should not show up in the UI
  enum :step_name, step_enum_values

  has_one_attached :logo_file

  validates :step_name, presence: true

  # Step-specific validations owned by the step object
  validate :run_step_object_validations, on: %w[
    settings
    issuer
    authentication
    logo_and_cert
    redirects
  ]

  ### end of validations copied from IdentityValidations::ServiceProviderValidation

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
    @@service_provider_to_wizard_attribute_map ||= ServiceProvider
      .attribute_names
      .each_with_object({}) do |attribute_name, hash|
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

  # This method fills out steps based on an existing service provider.
  # It was previously used in production. It is currently only referenced in the test suite.
  #
  # It's useful for setting up tests based on factory examples, and is
  # also a useful tool for debugging.
  def self.populate_data(service_provider, user)
    generate_steps(service_provider, user).each(&:save)
  end

  # This method fills out steps based on an existing service provider.
  # It was previously used in production. It is currently only referenced in the test suite.
  #
  # It's useful for setting up tests based on factory examples, and is
  # also a useful tool for debugging.
  def self.generate_steps(service_provider, user)
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
    self.wizard_form_data = enforce_valid_data(wizard_form_data)
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

  def existing_service_provider?
    !!original_service_provider
  end

  def original_service_provider
    id = get_step('hidden')&.service_provider_id
    id && ServiceProviderPolicy::Scope.new(user, ServiceProvider).resolve.find(id)
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
    (STEP_DATA.has_key?(step_name) && STEP_DATA[step_name].has_field?(method_name)) || super
  end

  def get_step(step_to_find)
    return self if step_name == step_to_find

    WizardStepPolicy::Scope.new(user, self.class)
      .resolve
      .find_or_initialize_by(user: user, step_name: step_to_find)
  end

  def ial
    return wizard_form_data['ial'] if step_name == 'authentication'

    get_step('authentication').ial
  end

  def production_ready?
    step_object('settings').production_ready?
  end

  def saml?
    step_object('protocol').saml?
  end

  def using_idv?
    ial.to_i > 1
  end

  def certificates
    return wizard_form_data['certs'] if step_name == 'logo_and_cert'

    get_step('logo_and_cert').certificates
  end

  private

  # Step objects hold step-specific behavior and read/write through the WizardStep they wrap.
  #
  # @param step_to_find [String] the step whose behavior we want
  # @return [Object] an instance of the WizardSteps step class
  def step_object(step_to_find)
    @step_objects ||= {}
    @step_objects[step_to_find.to_s] ||= begin
      record = get_step(step_to_find)
      WizardSteps::Registry.for_step_name(step_to_find).new(record)
    end
  end

  # Runs validations owned by the current step's step object and copies any
  # resulting errors onto this WizardStep so callers see a single error set.
  def run_step_object_validations
    step = step_object(step_name)
    return if step.valid?

    step.errors.each do |error|
      errors.add(error.attribute, error.message)
    end
  end

  def enforce_valid_data(new_data)
    return STEP_DATA[step_name].fields unless new_data.respond_to? :filter!

    new_data.filter! { |key, _v| STEP_DATA[step_name].has_field? key }
    STEP_DATA[step_name].fields.merge(new_data)
  end
end
