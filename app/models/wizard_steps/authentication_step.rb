module WizardSteps
  # Authentication settings: IAL, default AAL, and the requested attribute bundle.
  class AuthenticationStep
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    def self.fields
      {
        attribute_bundle: [],
        default_aal: 0,
        ial: '1',
      }
    end

    def self.step_name
      'authentication'
    end

    # delegates to the wizard_step model object
    # AttributeBundleValidator requires `attribute_bundle`, `ial`, and `saml?`
    delegate :attribute_bundle, :ial, :saml?, :wizard_form_data, to: :@wizard_step

    # Rails forms regularly put an initial, hidden, and blank entry for various inputs so that a
    # fallback blank exists if anything fails or gets skipped. ServiceProvider does this, too.
    before_validation :remove_blank_attributes

    validates_with AttributeBundleValidator

    # @param wizard_step [WizardStep] the record this step reads and writes through
    def initialize(wizard_step)
      @wizard_step = wizard_step
    end

    def remove_blank_attributes
      return if attribute_bundle.blank?

      wizard_form_data['attribute_bundle'] = attribute_bundle.reject(&:blank?)
    end
  end
end
