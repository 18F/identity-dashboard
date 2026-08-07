module WizardSteps
  # Localized custom help text shown to end users during sign in, sign up, and
  # forgot-password flows.
  class HelpTextStep
    def self.fields
      {
        help_text: {
          sign_in: { 'en' => '', 'es' => '', 'fr' => '', 'zh' => '' },
          sign_up: { 'en' => '', 'es' => '', 'fr' => '', 'zh' => '' },
          forgot_password: { 'en' => '', 'es' => '', 'fr' => '', 'zh' => '' },
        },
      }
    end

    def self.step_name
      'help_text'
    end
  end
end
