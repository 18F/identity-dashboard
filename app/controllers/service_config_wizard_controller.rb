class ServiceConfigWizardController < AuthenticatedController
  include ::Wicked::Wizard
  STEPS = WizardStep::STEPS
  steps(*STEPS)
  UPLOAD_STEP = 'logo_and_cert'
  attr_reader :wizard_step_model

  before_action :redirect_unless_flagged_in
  before_action -> { authorize step, policy_class: ServiceConfigPolicy }
  before_action :get_model_for_step, except: :new
  after_action :verify_authorized
  # We get false positives from `verify_policy_scoped` if we never instantiate a model
  after_action :verify_policy_scoped, unless: -> { when_skipping_models }
  helper_method %i[
    issuer_read_only?
    draft_service_provider
    show_saml_options?
    show_oidc_options?
    show_proof_failure_url?
  ]

  def new
    redirect_to service_config_wizard_path(Wicked::FIRST_STEP)
  end

  def show
    render_wizard
  end

  def update
    return destroy if can_cancel?
    if step == UPLOAD_STEP
      attach_cert
      remove_certificates
      attach_logo_file if logo_file_param
    end
    unless skippable && params[:wizard_step].blank?
      @model.data = @model.data.merge(wizard_step_params)
    end
    skip_step if @model.valid? && @model.save
    render_wizard
  end

  def destroy
    saved_steps = policy_scope(WizardStep).where(user: current_user)
    authorize saved_steps.last, :destroy?
    saved_steps.destroy_all
    redirect_to finish_wizard_path
  end

  def issuer_read_only?
    false # This will have to be updated when we add the ability to edit existing service providers
  end

  def draft_service_provider
    @service_provider ||= begin
      all_data = policy_scope(WizardStep).
        all.
        reduce({}) {|memo, record| memo.merge(record.data)}
      all_data['redirect_uris'] = [all_data['redirect_uris']]
      # This won't be enough to actually transfer the file to the new record
      # TODO: we'll have to add some code to do that file attach transfer
      all_data['logo'] = all_data.delete('logo_name')
      (all_data.keys - ServiceProvider.new.attributes.keys).each do |extra_data|
        # Clear out extra data from the wizard steps in case we put data
        # temporarily in the wizard steps that the service provider doesn't have attributes for
        all_data.delete[extra_data]
      end
      ServiceProvider.new(**all_data)
    end
  end

  def show_saml_options?
    auth_step && auth_step.identity_protocol == 'saml'
  end

  def show_oidc_options?
    !show_saml_options?
  end

  def show_proof_failure_url?
    auth_step && auth_step.ial.to_i > 1
  end

  private

  def get_model_for_step
    # The FINISH_STEP has no data. It's mostly a redirect. It doesn't need a model
    return if step == Wicked::FINISH_STEP
    @model = policy_scope(WizardStep).find_or_initialize_by(step_name: step)
  end

  def auth_step
    # Should this be `@model.auth_step` ?
    @auth_step ||= policy_scope(WizardStep).find_by(user: current_user, step_name: 'authentication')
  end

  def redirect_unless_flagged_in
    redirect_to service_providers_path unless IdentityConfig.store.service_config_wizard_enabled
  end

  def finish_wizard_path
    service_providers_path
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
      :redirect_uris,
      attribute_bundle: [],
      help_text: {},
    ]
    permit_params << :production_issuer if current_user.admin?
    # TODO: resync this with changes in https://gitlab.login.gov/lg/identity-dashboard/-/merge_requests/69
    permit_params << :email_nameid_format_allowed if current_user.admin?
    params.require(:wizard_step).permit(*permit_params)
  end

  # relies on ServiceProvider#certs_are_pems for validation
  def attach_cert
    return if params.dig(:wizard_step, :cert).blank?

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
    params[:wizard_step]&.fetch(:logo_file, nil)
  end

  def attach_logo_file
    return unless logo_file_param

    @model.logo_file.attach(logo_file_param)
    cache_logo_info
  end

  def cache_logo_info
    @model.data = @model.data.merge({
      logo_name: @model.logo_file.filename.to_s,
      remote_logo_key: @model.logo_file.key,
    })
  end

  def skippable
    step == UPLOAD_STEP
  end

  def can_cancel?
    params[:commit].present? &&
      params[:commit].downcase == 'cancel' &&
      IdentityConfig.store.service_config_wizard_enabled &&
      step == STEPS.last &&
      current_user.admin?
  end

  def when_skipping_models
    action_name == 'new' ||
      step == STEPS.first ||
      step == Wicked::FINISH_STEP
  end
end
