# Patch SimpleForm to work for JSON arrays
class JsonInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    merged_input_options = merge_wrapper_options(
      input_html_options, wrapper_options.merge(multiple: true)
    )

    values = object.public_send(attribute_name) || []
    values << [nil]

    fields = values.map do |value|
      @builder.text_field(attribute_name, merged_input_options.merge(value: value))
    end

    safe_join fields
  end
end
