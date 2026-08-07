module WizardSteps
  # Basic settings for the service provider: name, description, team, and
  # whether this is a production configuration.
  class SettingsStep
    include ActiveModel::Validations

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

    # delegates to the wizard_step model object
    delegate :app_name, :friendly_name, :group_id, to: :@wizard_step

    validates :app_name, presence: true
    validates :friendly_name, presence: true
    validates :group_id, presence: true
    validate :group_is_valid

    # @param wizard_step [WizardStep] the record this step reads and writes through
    def initialize(wizard_step)
      @wizard_step = wizard_step
    end

    # prod_config is a Boolean in the DB, but is a string in the form
    def production_ready?
      prod_config = @wizard_step.get_step('settings').prod_config
      ['true', true].include?(prod_config)
    end

    def group_is_valid
      errors.add(:group_id, :invalid) if Team.where(id: group_id).blank?
    end
  end
end
