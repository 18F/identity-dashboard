class ServiceProviderPolicy < BasePolicy
  attr_reader :user, :record

  BASE_PARAMS = [
    :acs_url,
    :active,
    :agency_id,
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
    { attribute_bundle: [],
      redirect_uris: [],
      help_text: {} },
  ].freeze

  ADMIN_PARAMS = (BASE_PARAMS + %i[
    email_nameid_format_allowed
    allow_prompt_login
    approved
  ]).freeze

  def permitted_attributes
    return ADMIN_PARAMS if logingov_admin?
    return BASE_PARAMS unless ial_readonly?

    BASE_PARAMS.reject { |param| param == :ial }
  end

  def index?
    true
  end

  def show?
    member_or_admin?
  end

  def new?
    return true unless IdentityConfig.store.access_controls_enabled

    logingov_admin? || user.user_teams.any? do |membership|
      membership.role == Role.find_by(name: 'partner_developer') ||
        membership.role == Role.find_by(name: 'partner_admin')
    end
  end

  def edit?
    return member_or_admin? unless IdentityConfig.store.access_controls_enabled

    logingov_admin? || (membership && !partner_readonly?)
  end

  def create?
    return true unless IdentityConfig.store.access_controls_enabled

    logingov_admin? || (membership && !partner_readonly?)
  end

  def update?
    return member_or_admin? unless IdentityConfig.store.access_controls_enabled

    logingov_admin? || (membership && !partner_readonly?)
  end

  def destroy?
    member_or_admin?
  end

  def all?
    logingov_admin?
  end

  def deleted?
    logingov_admin?
  end

  def edit_custom_help_text?
    logingov_admin?
  end

  def ial_readonly?
    # Passed the class instead of an instance. This usually happens when creating a new one.
    return false if record.instance_of?(Class)
    # readonly is for Prod edit
    return false if !IdentityConfig.store.prod_like_env || record.ial.blank?

    !logingov_admin?
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if logingov_admin?

      user.scoped_service_providers(scope:).reorder(nil)
    end
  end

  private

  def partner_readonly?
    membership.role == Role.find_by(name: 'partner_readonly')
  end

  def member_or_admin?
    return true if record.user == user && !IdentityConfig.store.access_controls_enabled

    logingov_admin? || !!membership
  end

  def membership
    team = record.team
    team && UserTeam.find_by(team:, user:)
  end
end
