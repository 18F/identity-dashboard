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

  STEP_DATA = {
    intro: WizardStep::Definition.new,
    settings: WizardStep::Definition.new({
      group_id: 0,
      prod_config: false,
      app_name: '',
      friendly_name: '',
      description: '',
    }),
    authentication: WizardStep::Definition.new({
      identity_protocol: ServiceProvider.identity_protocols.first,
      ial: 1,
      default_aal: nil,
      attribute_bundle: [],
    }),
    issuer: WizardStep::Definition.new({
      issuer: '',
    }),
    logo_and_cert: WizardStep::Definition.new({
      certs: [],
    }),
    redirects: WizardStep::Definition.new,
    help_text: WizardStep::Definition.new,
  }.with_indifferent_access.freeze
  STEPS = STEP_DATA.keys

  belongs_to :user
  enum step_name: STEPS.each_with_object(Hash.new) {|step, enum| enum[step] = step}.freeze
  has_one_attached :draft_logo_file

  validates :step_name, presence: true

  # SimpleForm uses this
  def self.reflect_on_association(relation)
    ServiceProvider.reflect_on_association(relation)
  end

  def valid?(*args)
    if args.blank? && step.present?
      super(step)
    else
      super
    end
  end

  def method_missing(name, *args, &block)
    if STEP_DATA.has_key?(step_name) && STEP_DATA[step_name].has_field?(name)
      data.with_indifferent_access[name] || STEP_DATA[step_name].fields[name]
    else
      super
    end
  end
end
