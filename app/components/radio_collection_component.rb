class RadioCollectionComponent < ViewComponent::Base
  attr_reader :form, :describedby, :model_method, :inputs, :default, :disabled

  # @param form [SimpleForm]
  # @param describedby [String] a proper value for `aria-describedby`
  # @param model_method [Symbol] such that the database has an associated column
  # @param inputs [Hash] hash where key is the label and value is the input value
  # @param options [Hash] additional options:

  # @option options [String] :default to pre-select one of the inputs, should match an input value
  # @option options [Boolean] :disabled whether this field is disabled
  # @option options [Boolean|nil] :additional_descriptions whether to pull additional descriptions
  #    for each radio option. This will look for I18n key formatted like
  #    "#{form_object_class_pluralized_with_underscores}.#{input_value}_description"
  def initialize(form:, describedby:, model_method:, inputs:, **options)
    @form = form
    @describedby = describedby
    @model_method = model_method
    @inputs = inputs
    @default = options[:default]
    @disabled = options[:disabled]
    @additional_descriptions = options[:additional_descriptions]
  end

  def button_and_label_for(input)
    button = input.radio_button(class: 'usa-radio__input', disabled: disabled)
    label = if @additional_descriptions
              label_with_extra_description(input)
            else
              input.label(class: 'usa-radio__label')
            end
    button + label
  end

  private

  # The use of `html_safe` should be good here because all other strings are either
  # defined statically or sanitized.
  # rubocop:disable Rails/OutputSafety
  def label_with_extra_description(input)
    label = input.label(class: 'usa-radio__label strong') do
      "<strong>#{sanitize input.text}</strong>".html_safe
    end
    description = sanitize I18n.t("#{form.object.class.to_s.tableize}.#{input.value}_description")
    "#{label} #{description}".html_safe
  end
  # rubocop:enable Rails/OutputSafety
end
