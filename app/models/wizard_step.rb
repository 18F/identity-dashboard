class WizardStep < ApplicationRecord
  class Definition
    attr_reader :fields
    def initialize(fields = {})
      @fields = fields.with_indifferent_access
    end
  end

  after_initialize do |model|
    if !model.data
      model.data = {}
    else
      model.data.filter! {|key, _v| STEP_DATA[result.step].include? key}
    end
  end
  

  STEP_DATA = {
    intro: WizardStep::Definition.new,
    settings: WizardStep::Definition.new({
      group_id: 0,
      prod_config: false,
      app_name: '',
      friendly_name: '',
      description: ''
    }),
    authentication: WizardStep::Definition.new({
      identity_protocol: ServiceProvider.identity_protocols.first,
      ial: 1,
      default_aal: nil
    }),
    issuer: WizardStep::Definition.new,
    logo_and_cert: WizardStep::Definition.new,
    redirects: WizardStep::Definition.new,
    help_text: WizardStep::Definition.new,
  }.with_indifferent_access.freeze
  STEPS = STEP_DATA.keys

  belongs_to :user
  enum step_name: STEPS

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
    if STEP_DATA.has_key?(step_name) && STEP_DATA[step_name].fields.has_key?(name)
      data[name] || STEP_DATA[step_name].fields[name]
    else
      super
    end
  end
end
