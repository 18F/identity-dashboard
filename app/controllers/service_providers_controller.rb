class ServiceProvidersController < AuthenticatedController
  before_action -> { authorize ServiceProvider }, only: [:index, :create, :new, :all, :deleted]
  before_action -> {
      authorize(service_provider, :member_or_admin?)
    }, only: %i[update edit show destroy]
  before_action :authorize_approval, only: [:update]
  before_action :authorize_allow_prompt_login, only: %i[create update]
  before_action :authorize_email_nameid_format_allowed, only: %i[create update]

  helper_method :parsed_help_text, :localized_help_text

  def index
    all_apps = current_user.scoped_service_providers

    prod_apps = all_apps.select { |sp| sp.prod_config == true }
    sandbox_apps = all_apps.select { |sp| sp.prod_config == false }

    @service_providers = build_service_provider_array(prod_apps, sandbox_apps)
  end

  def create
    @service_provider = ServiceProvider.new
    attach_cert

    @service_provider.assign_attributes(service_provider_params)
    attach_logo_file if logo_file_param
    service_provider.agency_id &&= service_provider.agency.id
    service_provider.user = current_user
    if helpers.help_text_options_enabled? && !current_user.admin
      service_provider.help_text = parsed_help_text.revert_unless_presets_only.to_localized_h
    end

    validate_and_save_service_provider(:new)
  end

  def update
    attach_cert
    remove_certificates

    service_provider.assign_attributes(service_provider_params)
    attach_logo_file if logo_file_param
    if helpers.help_text_options_enabled?
      help_text = parsed_help_text
      if !policy(@service_provider).edit_custom_help_text?
        help_text = parsed_help_text.revert_unless_presets_only
      end
      service_provider.help_text = help_text.to_localized_h
    end

    service_provider.agency_id &&= service_provider.agency.id
    validate_and_save_service_provider(:edit)
  end

  def destroy
    service_provider.destroy
    flash[:success] = I18n.t('notices.service_provider_deleted', issuer: service_provider.issuer)
    redirect_to service_providers_path
  end

  def new
    @service_provider = ServiceProvider.new
  end

  def edit; end

  def show
    @service_provider_versions = @service_provider.versions.reverse_order
  end

  def all
    return unless current_user.admin?
    all_apps = ServiceProvider.all.sort_by(&:created_at).reverse

    prod_apps = all_apps.select { |sp| sp.prod_config == true }
    sandbox_apps = all_apps.select { |sp| sp.prod_config == false }

    @service_providers = build_service_provider_array(prod_apps, sandbox_apps)
  end

  def publish
    if ServiceProviderUpdater.post_update == 200
      flash[:notice] = I18n.t('notices.service_providers_refreshed')
    else
      flash[:error] = I18n.t('notices.service_providers_refresh_failed')
    end
    redirect_to service_providers_path
  end

  def deleted
    @service_providers = deleted_service_providers
  end


  private

  def service_provider
    @service_provider ||= ServiceProvider.find(params[:id])
  end

  def parsed_help_text
    text_params = params.has_key?(service_provider) ? service_provider_params[:help_text] : nil
    @parsed_help_text ||= HelpText.lookup(
      params: text_params,
      service_provider: service_provider,
    )
  end

  def localized_help_text
    @localized_help_text ||= parsed_help_text.to_localized_h
  end

  def authorize_approval
    return unless params.require(:service_provider).key?(:approved) && !current_user.admin?
    raise Pundit::NotAuthorizedError, I18n.t('errors.not_authorized')
  end

  def authorize_allow_prompt_login
    return unless params.require(:service_provider).key?(:allow_prompt_login) &&
                  !current_user.admin?

    raise Pundit::NotAuthorizedError, I18n.t('errors.not_authorized')
  end

  def authorize_email_nameid_format_allowed
    return unless params.require(:service_provider).key?(:email_nameid_format_allowed) &&
                  !current_user.admin?

    raise Pundit::NotAuthorizedError, I18n.t('errors.not_authorized')
  end

  def validate_and_save_service_provider(initial_action)
    clear_formatting(@service_provider)

    @service_provider.valid?
    @service_provider.valid_saml_settings?

    return save_service_provider(@service_provider) if @service_provider.errors.none?

    flash[:error] = I18n.t('notices.service_providers_refresh_failed')
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
      flash[:error] = I18n.t('notices.service_providers_refresh_failed')
    end
  end

  def error_messages
    [[@errors] + [service_provider.errors.full_messages]].flatten.compact.to_sentence
  end

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
      :email_nameid_format_allowed,
      attribute_bundle: [],
      redirect_uris: [],
      help_text: {},
    ]
    params.require(:service_provider).permit(*permit_params)
  end

  # relies on ServiceProvider#certs_are_pems for validation
  def attach_cert
    return if params.dig(:service_provider, :cert).blank?

    service_provider.certs ||= []
    crt = params[:service_provider].delete(:cert).read
    service_provider.certs << crt unless crt.blank?
  end

  def remove_certificates
    return if params.dig(:service_provider, :remove_certificates).blank?

    to_remove_serials = params[:service_provider].delete(:remove_certificates)

    to_remove_serials.each do |serial|
      service_provider.remove_certificate(serial)
    end
  end

  def logo_file_param
    service_provider_params[:logo_file]
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
      service_provider: ServiceProviderSerializer.new(service_provider),
    }
  end

  def build_service_provider_array(prod_apps, sandbox_apps)
    return [
      {
        type: 'Production',
        apps: prod_apps,
      },
      {
        type: 'Sandbox',
        apps: sandbox_apps,
      },
    ]
  end

  def deleted_service_providers
    PaperTrail::Version.where(:item_type => 'ServiceProvider').
                       where(:event => 'destroy').
                       where('created_at > ?', 12.months.ago).
                       order(created_at: :desc)
  end

  helper_method :service_provider
end
