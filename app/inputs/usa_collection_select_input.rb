# Overriding to specify class for Identity Style Guide
class UsaCollectionSelectInput < SimpleForm::Inputs::CollectionSelectInput
  def input_html_classes
    super.push('usa-select').delete_if { |klass| klass == :usa_collection_select }
  end
end
