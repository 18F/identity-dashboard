# Overriding to specify class for Identity Style Guide
class UsaTextareaInput < SimpleForm::Inputs::TextInput
  def input_html_classes
    super.push('usa-textarea').delete_if { |klass| klass == :usa_textarea }
  end
end
