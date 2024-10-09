class ServiceConfigWizardController < AuthenticatedController
  include ::Wicked::Wizard
  STEPS = WizardStep::STEPS
  steps(*STEPS)
  UPLOAD_STEP = 'logo_and_cert'
  attr_reader :wizard_step_model

  before_action :redirect_unless_flagged_in
  before_action -> { authorize step, policy_class: ServiceConfigPolicy }
  before_action :get_model_for_step, except: %i[new create]
  after_action :verify_authorized
  after_action -> { flash.discard }, unless: -> { when_saving_config }
  # We get false positives from `verify_policy_scoped` if we never instantiate a model
  after_action :verify_policy_scoped, unless: -> { when_skipping_models }
  helper_method %i[
    issuer_read_only?
    draft_service_provider
    show_saml_options?
    show_oidc_options?
    show_proof_failure_url?
    parsed_help_text
  ]

  def new
    redirect_to service_config_wizard_path(Wicked::FIRST_STEP)
  end

  def show
    render_wizard
  end

  def create
    service_provider_id = params.require(:service_provider)

    # No existing config specified, so fall back on default behavior
    return new unless service_provider_id

    service_provider = policy_scope(ServiceProvider).find(service_provider_id)
    steps = WizardStep.steps_from_service_provider(service_provider, current_user)
    # TODO: what if the service provider is somehow invalid?
    steps.each(&:save)

    # Skip the intro when editing an existing config
    redirect_to service_config_wizard_path(STEPS[1])
  end

  def update
    return destroy if can_cancel?
    if step == UPLOAD_STEP
      attach_cert
      remove_certificates
      attach_logo_file if logo_file_param
    end
    unless skippable && params[:wizard_step].blank?
      @model.wizard_form_data = @model.wizard_form_data.merge(wizard_step_params)
    end
    if is_valid? && @model.save
      return save_to_service_provider if step == wizard_steps.last
      skip_step
    else
      flash[:error] = 'Please check the error(s) in the form below and re-submit.'
    end
    render_wizard
  end

  def destroy
    saved_steps = policy_scope(WizardStep).where(user: current_user)
    if saved_steps.any?
      authorize saved_steps.last, :destroy?
      saved_steps.destroy_all
    end
    redirect_to finish_wizard_path if can_cancel?
  end

  def is_valid?
    @model.valid?
    @model.saml_settings_present? if is_step('redirects')

    @model.errors.empty?
  end

  def issuer_read_only?
    @model.existing_service_provider?
  end

  def draft_service_provider
    @service_provider ||= begin
      all_wizard_data = WizardStep.all_step_data_for_user(current_user)
      service_provider = if @model.existing_service_provider?
        ServiceProvider.find(all_wizard_data['service_provider_id'])
      else
        ServiceProvider.new
      end
      service_provider.attributes = service_provider.attributes.merge(
        transform_to_service_provider_attributes(all_wizard_data),
      )
      service_provider
    end
  end

  def save_to_service_provider
    service_provider = draft_service_provider

    service_provider.agency_id &&= service_provider.agency.id
    service_provider.user ||= current_user
    if helpers.help_text_options_enabled? #&& !current_user.admin
      service_provider.help_text = parsed_help_text.revert_unless_presets_only.to_localized_h
    end

    logo_file = @model.get_step('logo_and_cert').logo_file
    service_provider.logo_file.attach(logo_file.blob) if logo_file.blob

    validate_and_save_service_provider
    return render_wizard if flash[:error].present?

    destroy
    redirect_to service_provider_path(service_provider)
  end

  def parsed_help_text
    text_params = @model.step_name == 'help_text' ? wizard_step_params[:help_text] : nil
    @parsed_help_text ||= if text_params.present?
      HelpText.lookup(
        params: text_params,
        service_provider: @service_provider || draft_service_provider,
      )
    else
      HelpText.new(service_provider: @service_provider || draft_service_provider)
    end
  end

  def convert_draft_to_full_sp
    service_provider = draft_service_provider

    service_provider.agency_id &&= service_provider.agency.id
    service_provider.user ||= current_user
    if helpers.help_text_options_enabled? && !current_user.admin
      ## TODO: This is to be fixed as part of https://cm-jira.usa.gov/browse/LG-14649
      # service_provider.help_text = parsed_help_text.revert_unless_presets_only.to_localized_h
      ##
      service_provider.help_text = {}
    end

    logo_file = @model.get_step('logo_and_cert').logo_file
    service_provider.logo_file.attach(logo_file.blob) if logo_file.blob

    validate_and_save_service_provider
    return render_wizard if flash[:error].present?

    destroy
    redirect_to service_provider_path(service_provider)
  end

  def show_saml_options?
    @model.saml?
  end

  def show_oidc_options?
    !show_saml_options?
  end

  def show_proof_failure_url?
    @model.ial.to_i > 1
  end

  def parsed_help_text
    ## TODO: This is to be fixed as part of https://cm-jira.usa.gov/browse/LG-14649
    
    # This is wrong
    HelpText.new(help_text: {})

    ## This is more correct but broken.
    ## I think the problem is that the form currently returns data like
    ## `{'sign_in' => 'blank'}`
    ## and the `HelpText.lookup` method is expecting it to be more like
    ## `{'sign_in' => { 'en' => 'blank'}}``
    ## (Not every language needs to be specified — `HelpText.lookup will` fill in the other languages if a preset option is chosen.)
    # text_params = params.has_key?(@model) ? wizard_step_params[:help_text] : nil
    # @parsed_help_text ||= HelpText.lookup(
    #   params: text_params,
    #   service_provider: @service_provider || draft_service_provider,
    # )
    ##
  end

  private

  def get_model_for_step
    # The FINISH_STEP has no data. It's mostly a redirect. It doesn't need a model
    return if step == Wicked::FINISH_STEP
    @model = policy_scope(WizardStep).find_or_initialize_by(step_name: step)
  end

  def is_step(step_name)
    step == step_name
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
    @model.attach_logo(logo_file_param)
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

  def when_saving_config
    action_name == 'update' &&
      step == STEPS.last ||
      step == Wicked::FINISH_STEP
  end

  def transform_to_service_provider_attributes(wizard_step_data)
    if wizard_step_data.has_key?('redirect_uris')
      wizard_step_data['redirect_uris'] = Array(wizard_step_data['redirect_uris'])
    end

    # This isn't enough to transfer the file contents to the new record.
    # That transfer is done elsewhere since it is not a simple attribute.
    if wizard_step_data.has_key?('logo_name')
      wizard_step_data['logo'] = wizard_step_data.delete('logo_name')
    end

    wizard_step_data['default_aal'] = nil if wizard_step_data['default_aal'].to_i == 0

    # Clear out extra data from the wizard steps in case we put data
    # temporarily in the wizard steps that the service provider doesn't have attributes for
    (wizard_step_data.keys - ServiceProvider.new.attributes.keys).each do |extra_data|
      wizard_step_data.delete(extra_data)
    end

    wizard_step_data
  end

  def validate_and_save_service_provider
    clear_formatting(@service_provider)

    @service_provider.valid?
    @service_provider.valid_saml_settings?

    return save_service_provider(@service_provider) if @service_provider.errors.none?

    flash[:error] = I18n.t('notices.service_providers_refresh_failed')
  end

  def save_service_provider(service_provider)
    service_provider.save!
    flash[:success] = I18n.t('notices.service_provider_saved', issuer: service_provider.issuer)
    publish_service_provider
  end

  def publish_service_provider
    if ServiceProviderUpdater.post_update(body_attributes) == 200
      flash[:notice] = I18n.t('notices.service_providers_refreshed')
    else
      flash[:error] = I18n.t('notices.service_providers_refresh_failed')
    end
  end

  def clear_formatting(service_provider)
    string_attributes = %w[
      issuer
      friendly_name
      description
      metadata_url
      acs_url
      assertion_consumer_logout_service_url
      sp_initiated_login_url
      return_to_sp_url
      failure_to_proof_url
      push_notification_url
      app_name
    ]

    service_provider.attributes.each do |k,v|
      v.try(:strip!) unless !string_attributes.include?(k)
    end

    if service_provider.redirect_uris
      service_provider.redirect_uris.each do |uri|
        uri.try(:strip!)
      end
    end
    service_provider
  end

  def body_attributes
    {
      service_provider: ServiceProviderSerializer.new(@service_provider),
    }
  end
end
