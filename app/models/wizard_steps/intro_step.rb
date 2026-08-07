module WizardSteps
  # Intro page. Has no form data of its own.
  class IntroStep
    def self.fields
      {}
    end

    def self.step_name
      'intro'
    end
  end
end
