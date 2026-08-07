module WizardSteps
  # Basic settings for the service provider: name, description, team, and
  # whether this is a production configuration.
  class SettingsStep
    def self.fields
      {
        app_name: '',
        description: '',
        friendly_name: '',
        group_id: nil,
        prod_config: false,
      }
    end

    def self.step_name
      'settings'
    end
  end
end
