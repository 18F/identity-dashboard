class ServiceProvidersController < AuthenticatedController
  before_action -> { authorize ServiceProvider }, only: %i[index all deleted prod_request]
  before_action -> { authorize service_provider }, only: %i[show edit update destroy]
  before_action :verify_environment_permissions, only: %i[new create]

  after_action :verify_authorized
  after_action :verify_policy_scoped,
               except: :publish # `#publish` is currently an API call only, so no DB scope required
  before_action :log_change, only: %i[destroy]

  helper_method :parsed_help_text, :localized_help_text

  def index
    skip_policy_scope # The #scoped_service_providers scope is good enough for now
    all_apps = current_user.scoped_service_providers

    prod_apps = all_apps.select { |sp| sp.prod_config == true }
    sandbox_apps = all_apps.select { |sp| sp.prod_config == false }

    @service_providers = build_service_provider_array(prod_apps, sandbox_apps)
  end

  def show
    @service_provider_versions = policy_scope(@service_provider.versions).reverse_order
    @show_status_indicator = IdentityConfig.store.prod_like_env &&
                             service_provider.prod_config? &&
                             policy(service_provider).see_status?
  end

  def new
    if IdentityConfig.store.service_config_wizard_enabled && IdentityConfig.store.prod_like_env
      redirect_to new_service_config_wizard_url
    end
    @service_provider = policy_scope(ServiceProvider).new
    authorize @service_provider
  end

  def edit
    if IdentityConfig.store.service_config_wizard_enabled && IdentityConfig.store.prod_like_env
      redirect_to service_config_wizard_index_path(service_provider: params[:id])
    end
  end

  def create
    @service_provider = policy_scope(ServiceProvider).new

    cert = params[:service_provider].delete(:cert)
    @service_provider.assign_attributes(permitted_attributes(service_provider))
    # We can't properly check authorization until after the user has a chance to assign a team
    authorize @service_provider

    # Probably better to only attach a cert after checking the user has permission
    attach_cert(cert)

    attach_logo_file if logo_file_param
    service_provider.agency_id &&= service_provider.agency.id
    service_provider.user = current_user
    if helpers.help_text_options_enabled? && !current_user.logingov_admin?
      service_provider.help_text = parsed_help_text.revert_unless_presets_only.to_localized_h
    end

    validate_and_save_service_provider(:new)
    log_change
  end

  def update
    cert = params[:service_provider].delete(:cert)
    attach_cert(cert)
    remove_certificates

    help_text = parsed_help_text
    service_provider.assign_attributes(permitted_attributes(service_provider))
    attach_logo_file if logo_file_param
    if helpers.help_text_options_enabled?
      unless policy(@service_provider).edit_custom_help_text?
        help_text = help_text.revert_unless_presets_only
      end
      service_provider.help_text = help_text.to_localized_h
    end

    service_provider.agency_id &&= service_provider.agency.id
    validate_and_save_service_provider(:edit)
    log_change
  end

  def destroy
    service_provider.destroy
    flash[:success] = I18n.t('notices.service_provider_deleted', issuer: service_provider.issuer)
    redirect_to service_providers_path
  end

  def all
    all_apps = policy_scope(ServiceProvider).order(created_at: :desc)

    prod_apps = all_apps.select { |sp| sp.prod_config == true }
    sandbox_apps = all_apps.select { |sp| sp.prod_config == false }

    @service_providers = build_service_provider_array(prod_apps, sandbox_apps)
  end

  def publish
    authorize ServiceProviderUpdater
    if ServiceProviderUpdater.post_update == 200
      flash[:notice] = I18n.t('notices.service_providers_refreshed')
    else
      flash[:error] = "#{I18n.t('notices.service_providers_refresh_failed')} Ref: 84"
    end
    redirect_to service_providers_path
  end

  def deleted
    @service_providers = deleted_service_providers
  end

  def prod_request
    @service_provider ||= policy_scope(ServiceProvider).find_by(id: params[:service_provider][:id])
    portal_url = Rails.application.routes.url_helpers.service_provider_url(@service_provider,
host: request.host)

    zendesk_request = ZendeskRequest.new(current_user, portal_url, @service_provider)

    ticket_custom_fields = []
    zendesk_request.ticket_field_functions.each_with_object(Hash.new) do |(id, func), result|
      ticket_custom_fields.push({ id: id,
value: func.to_proc.call(@service_provider) })
    end

    ZendeskRequest::ZENDESK_TICKET_FIELD_INFORMATION.keys.each do |key|
      ticket_custom_fields.push({ id: key, value: params[:service_provider][key.to_s.to_sym] })
    end

    ticket_data = zendesk_request.build_zendesk_ticket(ticket_custom_fields)

    creation_status = zendesk_request.create_ticket(ticket_data)

    if creation_status[:success] == true
      flash[:success] = "Request submitted successfully. Ticket ##{creation_status[:ticket_id]} \
        has been created on your behalf, replies will be sent to #{current_user.email}."
    else
      flash[:error] =
        "Unable to submit request. #{creation_status[:errors].join(', ')}. Please try again."
    end
      redirect_to action: 'show', id: @service_provider.id
  end

  private

  def service_provider
    # TODO: improve the 404 page and let this be a `find` that raises a `NotFound` error,
    # removing the `not_authorized` error
    @service_provider ||= policy_scope(ServiceProvider).find_by(id: params[:id])

    @service_provider || raise(Pundit::NotAuthorizedError, I18n.t('errors.not_authorized'))
  end

  def parsed_help_text
    if params.has_key?(:service_provider)
      text_params = permitted_attributes(service_provider)[:help_text]
    end
    HelpText.lookup(params: nil, service_provider: service_provider)
    @parsed_help_text ||= HelpText.lookup(
      params: text_params,
      service_provider: service_provider,
    )
  end

  def localized_help_text
    @localized_help_text ||= parsed_help_text.to_localized_h
  end

  def validate_and_save_service_provider(initial_action)
    clear_formatting(@service_provider)

    @service_provider.valid?
    @service_provider.valid_saml_settings?
    @service_provider.valid_localhost_uris? if !current_user.logingov_admin?

    return save_service_provider(@service_provider) if @service_provider.errors.none?

    flash[:error] = "#{I18n.t('notices.service_providers_refresh_failed')} Ref: 139"
    render initial_action
  end

  def save_service_provider(service_provider)
    service_provider.save!
    flash[:success] = I18n.t('notices.service_provider_saved', issuer: service_provider.issuer)
    publish_service_provider
    redirect_to service_provider_path(service_provider)
  end

  def publish_service_provider
    if ServiceProviderUpdater.post_update(body_attributes) == 200
      flash[:notice] = I18n.t('notices.service_providers_refreshed')
    else
      flash[:error] = "#{I18n.t('notices.service_providers_refresh_failed')} Ref: 154"
    end
  end

  # relies on ServiceProvider#certs_are_pems for validation
  def attach_cert(cert)
    return if cert.blank?

    service_provider.certs ||= []
    crt = cert.read
    service_provider.certs << crt if crt.present?
  end

  def remove_certificates
    return if params.dig(:service_provider, :remove_certificates).blank?

    to_remove_serials = params[:service_provider].delete(:remove_certificates)

    to_remove_serials.each do |serial|
      service_provider.remove_certificate(serial)
    end
  end

  def logo_file_param
    permitted_attributes(service_provider)[:logo_file]
  end

  def attach_logo_file
    return unless logo_file_param

    service_provider.logo_file.attach(logo_file_param)
    cache_logo_info
  end

  def cache_logo_info
    service_provider.logo = service_provider.logo_file.filename.to_s
    service_provider.remote_logo_key = service_provider.logo_file.key
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

    service_provider.attributes.each do |k, v|
      v.try(:strip!) if string_attributes.include?(k)
    end

    service_provider.redirect_uris&.each do |uri|
      uri.try(:strip!)
    end
    service_provider
  end

  def body_attributes
    {
      service_provider: ServiceProviderSerializer.new(service_provider),
    }
  end

  def build_service_provider_array(prod_apps, sandbox_apps)
    prod_hash = { type: 'Production', apps: prod_apps }
    sandbox_hash = { type: 'Sandbox', apps: sandbox_apps }

    if IdentityConfig.store.prod_like_env
      [prod_hash]
    else
      [prod_hash, sandbox_hash]
    end
  end

  def deleted_service_providers
    dsp = policy_scope(PaperTrail::Version).where(item_type: 'ServiceProvider').
                       where(event: 'destroy').
                       where('created_at > ?', 12.months.ago).
                       order(created_at: :desc)
    # ensure that we associate an agency if possible
    dsp.each do |sp|
      if !sp.object['agency_id'] && sp.object['group_id']
        sp.object['agency_id'] = Team.find_by(id: sp.object['group_id'])&.agency_id
      end
    end

    dsp
  end

  helper_method :service_provider

  def log_change
    log.record_save(action_name, service_provider)
  end

  def verify_environment_permissions
    return unless IdentityConfig.store.prod_like_env

    redirect_to service_providers_path
  end
end
