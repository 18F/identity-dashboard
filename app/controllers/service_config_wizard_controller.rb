class ServiceConfigWizardController < ApplicationController
  include ::Wicked::Wizard
  STEPS = %i[intro settings authentication issuer logo_and_cert redirects help_text]
  steps(*STEPS)

  before_action :redirect_unless_flagged_in
  before_action -> { authorize step, policy_class: ServiceConfigPolicy }
  before_action :get_service_provider
  after_action :verify_authorized
  after_action :verify_policy_scoped

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

  private

  def get_service_provider
    @service_provider ||= policy_scope(ServiceProvider).new
  end

  def redirect_unless_flagged_in
    unless IdentityConfig.store.service_config_wizard_enabled
      redirect_to service_providers_path
      return
    end
    redirect_to service_providers_path unless current_user.admin?
  end
end
