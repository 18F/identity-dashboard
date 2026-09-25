module WizardSteps
  # The service provider's issuer string.
  class IssuerStep
    include ActiveModel::Validations

    def self.fields
      { issuer: '' }
    end

    def self.step_name
      'issuer'
    end

    delegate :issuer, to: :@wizard_step

    validates :issuer, presence: true
    validates :issuer,
      format: { with: IdentityValidations::ServiceProviderValidation::ISSUER_FORMAT_REGEXP }
    validate :issuer_service_provider_uniqueness

    # @param wizard_step [WizardStep] the record this step reads and writes through
    def initialize(wizard_step)
      @wizard_step = wizard_step
    end

    def issuer_service_provider_uniqueness
      return if existing_config_is_this_one?

      errors.add(:issuer, 'already in use') if ServiceProvider.where(issuer:).any?
    end

    def existing_config_is_this_one?
      @wizard_step.original_service_provider&.issuer == issuer
    end
  end
end
