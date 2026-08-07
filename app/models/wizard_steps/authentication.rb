# Namespace for WizardSteps
module WizardStep
  # Container for the Authentication Step
  class Authentication
    attr_reader :fields

    def initialize(fields = {})
      @fields = fields.with_indifferent_access
    end

    def has_field?(name)
      fields.key?(name)
    end
  end
end
