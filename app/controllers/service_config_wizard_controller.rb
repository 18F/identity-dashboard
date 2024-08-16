class ServiceConfigWizardController < AuthenticatedController
  include ::Wicked::Wizard
  STEPS = %i[intro settings authentication issuer logo_and_cert redirects help_text]
  steps(*STEPS)

  before_action :redirect_unless_flagged_in
  before_action -> { authorize step, policy_class: ServiceConfigPolicy }
  after_action :verify_authorized
  after_action :verify_policy_scoped, if: proc { |c| c.action_name != 'new' && (c.action_name != 'show' || c.step != :intro) }

  helper_method :service_provider, :first_step?, :last_step?

  def new
    redirect_to service_config_wizard_path(Wicked::FIRST_STEP)
  end

  def show
    get_service_provider_draft
    render_wizard
  end

  def update
    if service_provider.valid?(step)
      skip_step
    end
    render_wizard
  end

  def first_step?
    step.eql? wizard_steps.first
  end

  def last_step?
    step.eql? wizard_steps.last
  end

  private

  def service_config
    if session.has_key?(:service_config)
      return get_service_provider(session[:service_config].merge(service_provider_params))
    end
    session[:service_config] = get_service_provider.attributes
  end

  def get_service_provider_draft
    service_provider({})
  end

  def service_provider(params = nil)
    params ||= service_provider_params
    @service_provider ||= if ServiceProviderDraft.exists?(session)
      draft = ServiceProviderDraft.find(session)
      draft.update(policy_scope(ServiceProvider).new(params).attributes, self.step)
      draft
    else
      ServiceProviderDraft.new(session, policy_scope(ServiceProvider).new.attributes.merge(params))
    end
  end

  def redirect_unless_flagged_in
    redirect_to service_providers_path unless IdentityConfig.store.service_config_wizard_enabled
  end

  # Copied from ServiceProvidersController
  def service_provider_params
    permit_params = [
      :acs_url,
      :active,
      :agency_id,
      :allow_prompt_login,
      :approved,
      :assertion_consumer_logout_service_url,
      :block_encryption,
      :description,
      :friendly_name,
      :group_id,
      :ial,
      :default_aal,
      :identity_protocol,
      :issuer,
      :logo,
      :metadata_url,
      :return_to_sp_url,
      :failure_to_proof_url,
      :push_notification_url,
      :signed_response_message_requested,
      :sp_initiated_login_url,
      :logo_file,
      :app_name,
      :prod_config,
      attribute_bundle: [],
      redirect_uris: [],
      help_text: {},
    ]
    permit_params << :production_issuer if current_user.admin?
    permit_params << :email_nameid_format_allowed if current_user.admin?
    params.require(:service_provider_draft).permit(*permit_params)
  end

  def update_storage(data)
    # noop
  end
  def set_errors
    flash[:error] = "error goes here"
  end
end
