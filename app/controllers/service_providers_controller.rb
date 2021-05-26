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
    if IdentityConfig.store.risc_notifications_eventbridge_enabled
      RiscDestinationUpdater.new(service_provider).remove
    end
    service_provider.destroy
    flash[:success] = I18n.t('notices.service_provider_deleted', issuer: service_provider.issuer)
    redirect_to service_providers_path
  end

  def new
    @service_provider = ServiceProvider.new
  end

  def edit; end

  def show; end

  def all
    return unless current_user.admin?
    @service_providers = ServiceProvider.all.sort_by(&:created_at).reverse
  end

  private

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
    return save_service_provider if service_provider.valid?
    flash[:error] = I18n.t('notices.service_providers_refresh_failed')
    render initial_action
  end

  def save_service_provider
    service_provider.save!
    flash[:success] = I18n.t('notices.service_provider_saved', issuer: service_provider.issuer)
    update_eventbridge_risc_notifications
    publish_service_providers
    redirect_to service_provider_path(service_provider)
  end

  def publish_service_providers
    if ServiceProviderUpdater.ping == 200
      flash[:notice] = I18n.t('notices.service_providers_refreshed')
    else
      flash[:error] = I18n.t('notices.service_providers_refresh_failed')
    end
  end

  def update_eventbridge_risc_notifications
    if IdentityConfig.store.risc_notifications_eventbridge_enabled
      RiscDestinationUpdater.new(service_provider).update!
    end
  end

  def notify_users(service_provider, initial_action)
    if initial_action == :new
      notify_users_new_service_provider(service_provider)
    elsif service_provider.recently_approved?
      notify_users_approved_service_provider(service_provider)
    end
  end

  def notify_users_new_service_provider(service_provider)
    UserMailer.admin_new_service_provider(service_provider).deliver_later
    UserMailer.user_new_service_provider(service_provider).deliver_later
  end

  def notify_users_approved_service_provider(service_provider)
    UserMailer.admin_approved_service_provider(service_provider).deliver_later
    UserMailer.user_approved_service_provider(service_provider).deliver_later
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
      :sp_initiated_login_url,
      :logo_file,
      attribute_bundle: [],
      redirect_uris: [],
      help_text: {},
    ]
    permit_params << :production_issuer if current_user.admin?
    params.require(:service_provider).permit(*permit_params)
  end

  # relies on ServiceProvider#certs_are_pems for validation
  def attach_cert
    return if params.dig(:service_provider, :cert).blank?

    service_provider.certs ||= []
    service_provider.certs << params[:service_provider].delete(:cert).read
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

  def using_s3?
    Rails.application.config.active_storage.service == :amazon
  end

  def s3
    @s3 ||= Aws::S3::Client.new(region: IdentityConfig.store.aws_region)
  end

  def add_iaa_warning
    flash.now[:warning] = I18n.t('notices.service_provider_iaa_notice')
  end

  helper_method :service_provider
end
