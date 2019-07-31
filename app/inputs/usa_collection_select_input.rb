class UsaCollectionSelectInput < SimpleForm::Inputs::CollectionSelectInput
  def input_html_classes
    super.push('usa-select').delete_if { |x| x == :usa_collection_select }
  end
end