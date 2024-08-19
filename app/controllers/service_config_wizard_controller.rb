class ServiceConfigWizardController < AuthenticatedController
  include ::Wicked::Wizard
  STEPS = WizardStep::STEPS
  steps(*STEPS)
  CERT_STEP = 'logo_and_cert'
  LOGO_STEP = 'logo_and_cert'
  attr_reader :wizard_step_model

  before_action :redirect_unless_flagged_in
  before_action -> { authorize step, policy_class: ServiceConfigPolicy }
  before_action :get_model_for_step, except: :new
  after_action :verify_authorized
  # after_action :verify_policy_scoped
  helper_method :first_step?, :last_step?

  def new
    redirect_to service_config_wizard_path(Wicked::FIRST_STEP)
  end

  def show
    render_wizard
  end

  def update
    if step == CERT_STEP
      attach_cert
      remove_certificates
      attach_logo_file if logo_file_param
    end
    @model.data = @model.data.merge(wizard_step_params)
    skip_step if @model.save
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

  def wizard_step_params
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
    params.require(:wizard_step).permit(*permit_params)
  end

  # relies on ServiceProvider#certs_are_pems for validation
  def attach_cert
    return if params.dig(:wizard_step, :cert).blank?

    @model.certs ||= []
    crt = params[:wizard_step].delete(:cert).read
    @model.certs << crt unless crt.blank?
  end

  def remove_certificates
    return if params.dig(:wizard_step, :remove_certificates).blank?

    to_remove_serials = params[:wizard_step].delete(:remove_certificates)

    to_remove_serials.each do |serial|
      @model.remove_certificate(serial)
    end
  end

  def logo_file_param
    wizard_step_params[:logo_file]
  end

  def attach_logo_file
    return unless logo_file_param

    @model.logo_file.attach(logo_file_param)
    cache_logo_info
  end
end
