# Namespace for WizardSteps
module WizardSteps
  # Container for the Settings Step
  class Settings < WizardStep
    validates :app_name, presence: true, on: 'settings'
    validates :group_id, presence: true, on: 'settings'
    validate :group_is_valid, on: 'settings'

    attr_reader :app_name, :description, :friendly_name, :group_id, :prod_config

    def initialize(options)
      @app_name = options[:app_name]
      @description = options[:description]
      @friendly_name = options[:friendly_name]
      @group_id = options[:group_id]
      @prod_config = options[:prod_config]
      super
    end

    def wizard_form_data
      {
        'app_name' => app_name,
        'description' => description,
        'friendly_name' => friendly_name,
        'group_id' => group_id,
        'prod_config' => prod_config,
      }
    end
  end
end
