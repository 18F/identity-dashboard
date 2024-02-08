class ServiceProvidersController < AuthenticatedController
  before_action :authorize_service_provider
  before_action :authorize_approval, only: [:update]
  before_action :authorize_allow_prompt_login, only: %i[create update]
  before_action :add_iaa_warning, except: %i[index destroy]

  def index; end

  def create
    @service_provider = ServiceProvider.new
    attach_cert

    @service_provider.assign_attributes(service_provider_params)
    attach_logo_file if logo_file_param
    service_provider.agency_id &&= service_provider.agency.id
    service_provider.user = current_user
    validate_and_save_service_provider(:new)
  end

  def update
    attach_cert
    remove_certificates

    service_provider.assign_attributes(service_provider_params)
    attach_logo_file if logo_file_param

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
    @help_text_empty = help_text_empty?
  end

  def edit
    @help_text_empty = help_text_empty?
  end

  def show; end

  def all
    return unless current_user.admin?
    @service_providers = ServiceProvider.all.sort_by(&:created_at).reverse
  end

  private

  def help_text_empty?
    service_provider.help_text['sign_in'].empty? &&
      service_provider.help_text['sign_up'].empty? &&
      service_provider.help_text['forgot_password'].empty?
  end

  def service_provider
    @service_provider ||= ServiceProvider.find(params[:id])
  end

  def authorize_service_provider
    authorize service_provider if %i[update edit show destroy].include?(action_name.to_sym)
    authorize ServiceProvider if action_name == 'all'
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

  def validate_and_save_service_provider(initial_action)
    formatted_sp = clear_formatting(@service_provider)
    return save_service_provider(formatted_sp) if formatted_sp.valid?

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
      attribute_bundle: [],
      redirect_uris: [],
      help_text: {},
    ]
    permit_params << :production_issuer if current_user.admin?
    permit_params << :email_nameid_format_allowed if current_user.admin?
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

  def add_iaa_warning
    flash.now[:warning] = I18n.t('notices.service_provider_iaa_notice')
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
      production_issuer
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

  helper_method :service_provider
end
