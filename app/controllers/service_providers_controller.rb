class ServiceProvidersController < AuthenticatedController
  before_action :authorize_service_provider, only: %i(update edit show destroy)
  before_action :authorize_approval, only: [:update]

  def index; end

  def create
    @service_provider = ServiceProvider.new(service_provider_params)
    service_provider.user = current_user
    validate_and_save_service_provider(:new)
  end

  def update
    service_provider.assign_attributes(service_provider_params)
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

  def show; end

  def all
    @service_providers = ServiceProvider.all if current_user.admin?
  end

  private

  def authorize_service_provider
    authorize service_provider
  end

  def service_provider
    @service_provider ||= ServiceProvider.find(params[:id])
  end

  def authorize_approval
    return unless params.require(:service_provider).key?(:approved) && !current_user.admin?
    raise Pundit::NotAuthorizedError, I18n.t('errors.not_authorized')
  end

  def validate_and_save_service_provider(initial_action)
    if service_provider.valid?
      save_service_provider(initial_action)
    else
      flash[:error] = error_messages
      render initial_action
    end
  end

  def save_service_provider(initial_action)
    service_provider.save!
    flash[:success] = I18n.t('notices.service_provider_saved', issuer: service_provider.issuer)
    publish_service_providers
    redirect_to service_provider_path(service_provider)
  end

  def publish_service_providers
    if ServiceProviderUpdater.ping
      flash[:notice] = I18n.t('notices.service_providers_refreshed')
    else
      flash[:error] = I18n.t('notices.service_providers_refresh_failed')
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

  # rubocop:disable MethodLength
  def service_provider_params
    params.require(:service_provider).permit(
      :acs_url,
      :active,
      :agency_id,
      :approved,
      :assertion_consumer_logout_service_url,
      :block_encryption,
      :description,
      :friendly_name,
      :issuer,
      :logo,
      :metadata_url,
      :return_to_sp_url,
      :saml_client_cert,
      :sp_initiated_login_url,
      :group_id,
      :identity_protocol,
      attribute_bundle: [],
      redirect_uris: [],
    )
  end
  # rubocop:enable MethodLength

  helper_method :service_provider
end
