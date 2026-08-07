module WizardSteps
  # The single source of truth for the ordered list of Guided Flow steps.
  #
  # Determines the sequence of pages in the wizard and the order in which WizardStep::STEP_DATA
  # (and everything derived from it) is built. The `hidden` step is included here but
  # excluded from  WizardStep::STEPS, since it is not shown in the UI.
  module Registry
    # Ordered list of the step classes that make up the Guided Flow.
    STEP_CLASSES = [
      IntroStep,
      SettingsStep,
      ProtocolStep,
      AuthenticationStep,
      IssuerStep,
      LogoAndCertStep,
      RedirectsStep,
      HelpTextStep,
      HiddenStep,
    ].freeze

    # The step name that is intentionally hidden from the UI.
    HIDDEN_STEP_NAME = HiddenStep.step_name

    module_function

    # @return [Array<Class>] the ordered step classes
    def step_classes
      STEP_CLASSES
    end

    # @return [Class, nil] the step class for a given step name
    def for_step_name(step_name)
      STEP_CLASSES.find { |klass| klass.step_name == step_name.to_s }
    end
  end
end
