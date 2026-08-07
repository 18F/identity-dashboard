# Namespace for WizardSteps
module WizardSteps
  # Container for the HelpText Step
  class Hidden
    attr_reader :fields

    def initialize(fields = {})
      @fields = fields.with_indifferent_access
    end

    def has_field?(name)
      fields.key?(name)
    end
  end
end
