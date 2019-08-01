class UsaTextareaInput < SimpleForm::Inputs::TextInput
  def input_html_classes
    super.push('usa-textarea').delete_if { |x| x == :usa_textarea }
  end
end
