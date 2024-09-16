# require 'pry'
# module SimpleForm
#   module Components
#     module CustomLabels
#       extend SimpleForm::Components::Labels
#       # include SimpleForm::Helpers::HasErrors

#       def label_text(wrapper_options = nil)
#         label_text = options[:label_text] || SimpleForm.label_text
#         errors = SimpleForm.errors
#         full_label_text = errors.has_errors? ? label_text + " " + errors.error_text : label_text
#         full_label_text.call(html_escape(raw_label_text), required_label_text, options:[:label].present?).strip.html_safe
#       end
#     end
#   end

#   module Inputs
#     class Base
#       include SimpleForm::Components::CustomLabels
#     end
#   end
# end

# class LabelErrorsInput < SimpleForm::Inputs::Base
#   def input(wrapper_options)

#     merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
#     merged_input_options[:label] = ("#{merged_input_options[:label]}<p class='usa-sr-only'>#{@builder.object.errors.full_messages_for(attribute_name).join('. ')}</p>").html_safe
#     merged_input_options.delete(:as)
#     "#{@builder.input(attribute_name, merged_input_options)}".html_safe
#   end
# end

# class WizardFormBuilder < SimpleForm::FormBuilder
#   def input(attribute_name, options = {}, &block)
#     super(attribute_name, options, &block)
#   end

#   def get_attribute_name
#     attribute_name
#   end
# end
