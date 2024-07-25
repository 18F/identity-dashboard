class IntegrationSetupController < ApplicationController
  include ::Wicked::Wizard
  STEPS = %i[intro settings authentication issuer logo_and_cert redirects help_text]
  steps(*STEPS)

  before_action -> { authorize step, policy_class: IntegrationSetupPolicy }
  before_action :get_service_provider
  after_action :verify_authorized
  after_action :verify_policy_scoped

  def new
    redirect_to integration_setup_path(Wicked::FIRST_STEP)
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
end
