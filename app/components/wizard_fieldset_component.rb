# frozen_string_literal: true

# A fieldset for the ServiceConfigWizard
class WizardFieldsetComponent < ViewComponent::Base
  attr_reader :form, :input_type, :required, :model_method, :param_name, :description_key,
              :inputs, :label_translation_key, :default

  use_helper :accessible_label, from: ServiceConfigWizardHelper

  # @param form [Method] such that form is a valid instance of wizard_form
  # @param input_type ["radio"|"checkbox"]
  # @param param_name [Symbol] the parameter name to use when submitting the form
  # @param inputs [Hash] input items such that the input fields are rendered correctly
  # @param options [Hash] additional options:
  #
  # @option options [String] :description_key a translation subkey under `service_provider_form`
  #   defaults to `"#{model_method}_html"`, pass an empty string to skip the description
  # @option options [Boolean] :required whether this field is required
  # @option options [Symbol,String] :model_method the method to use when pulling the current value,
  #           defaults to `param_name`
  # @option options [Symbol,String] :label_key if the label translation for the field should be different
  #           from `model_method`
  # @option options [String] :default to pre-select an option
  def initialize(form:, input_type:, param_name:, inputs:, **options) # rubocop:disable Lint/MissingSuper
    @form = form
    @input_type = input_type
    @param_name = options[:param_name]
    @inputs = inputs
    @model_method = options[:model_method] || @param_name
    @required = options[:required]
    @description_key = options[:description_key] || "#{model_method}_html"
    @label_translation_key = options[:label_key] || model_method
    @default = options[:default]
  end

  def required_class
    required ? 'required' : 'optional'
  end

  def description?
    @description_key.present?
  end
end
