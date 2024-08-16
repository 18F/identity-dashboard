class ServiceConfigWizardController < AuthenticatedController
  include ::Wicked::Wizard
  STEPS = WizardStep::STEPS
  steps(*STEPS)

  before_action :redirect_unless_flagged_in
  before_action -> { authorize step, policy_class: ServiceConfigPolicy }
  before_action :get_model_for_step, except: :new
  after_action :verify_authorized
  helper_method :first_step?, :last_step?

  def new
    redirect_to service_config_wizard_path(Wicked::FIRST_STEP)
  end

  def show
    render_wizard
  end

  def update
    skip_step
    render_wizard
  end

  def first_step?
    step.eql? wizard_steps.first
  end

  def last_step?
    step.eql? wizard_steps.last
  end

  private

  def get_model_for_step
    @model = policy_scope(WizardStep).find_or_initialize_by(step_name: step)
  end

  def redirect_unless_flagged_in
    redirect_to service_providers_path unless IdentityConfig.store.service_config_wizard_enabled
  end
end
