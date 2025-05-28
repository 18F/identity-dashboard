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
    return ADMIN_PARAMS if user_has_login_admin_role?
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

    user_has_login_admin_role? || user.user_teams.any? do |membership|
      membership.role == Role.find_by(name: 'partner_developer') ||
        membership.role == Role.find_by(name: 'partner_admin')
    end
  end

  def edit?
    return member_or_admin? unless IdentityConfig.store.access_controls_enabled

    user_has_login_admin_role? || (membership && !partner_readonly?)
  end

  def create?
    return true unless IdentityConfig.store.access_controls_enabled
    return user_has_login_admin_role? if IdentityConfig.store.prod_like_env

    user_has_login_admin_role? || (membership && !partner_readonly?)
  end

  def update?
    return member_or_admin? unless IdentityConfig.store.access_controls_enabled

    user_has_login_admin_role? || (membership && !partner_readonly?)
  end

  def destroy?
    return user_has_login_admin_role? if IdentityConfig.store.prod_like_env
    return member_or_admin? unless IdentityConfig.store.access_controls_enabled
    return false if !membership && !user_has_login_admin_role?

    user_has_login_admin_role? || partner_admin? || creator?
  end

  def all?
    user_has_login_admin_role?
  end

  def deleted?
    user_has_login_admin_role?
  end

  def prod_request?
    user_has_login_admin_role? || (membership && !partner_readonly?)
  end

  def edit_custom_help_text?
    user_has_login_admin_role?
  end

  def ial_readonly?
    # Passed the class instead of an instance. This usually happens when creating a new one.
    return false if record.instance_of?(Class)
    # readonly is for Prod edit
    return false if !IdentityConfig.store.prod_like_env || record.ial.blank?

    !user_has_login_admin_role?
  end

  def see_status?
    user_has_login_admin_role?
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if user_has_login_admin_role?

      user.scoped_service_providers(scope:).reorder(nil)
    end
  end

  private

  def partner_readonly?
    membership.role == Role.find_by(name: 'partner_readonly')
  end

  def partner_admin?
    membership.role == Role.find_by(name: 'partner_admin')
  end

  def member_or_admin?
    return true if record.user == user && !IdentityConfig.store.access_controls_enabled

    user_has_login_admin_role? || !!membership
  end

  def creator?
    user.id == record.user_id
  end

  def membership
    team = record.team
    team && UserTeam.find_by(team:, user:)
  end
end
