class ServiceProviderPolicy < BasePolicy
  attr_reader :user, :record

  def index?
    true
  end

  def show?
    member_or_admin?
  end

  def new?
    return true unless IdentityConfig.store.access_controls_enabled

    admin? || user.user_teams.any? do |membership|
      membership.role == Role.find_by(name: 'partner_developer') ||
        membership.role == Role.find_by(name: 'partner_admin')
    end
  end

  def edit?
    return member_or_admin? unless IdentityConfig.store.access_controls_enabled

    admin? || (membership && !partner_readonly?)
  end

  def create?
    return true unless IdentityConfig.store.access_controls_enabled

    admin? || (membership && !partner_readonly?)
  end

  def update?
    return member_or_admin? unless IdentityConfig.store.access_controls_enabled

    admin? || (membership && !partner_readonly?)
  end

  def destroy?
    member_or_admin?
  end

  def all?
    admin?
  end

  def deleted?
    admin?
  end

  def edit_custom_help_text?
    admin?
  end

  def ial_read_only?
    return false unless IdentityConfig.store.access_controls_enabled && IdentityConfig.store.prod_like_env

    !(admin? || membership.role == Role::SITE_ADMIN)
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if admin?

      user.scoped_service_providers(scope:).reorder(nil)
    end
  end

  private

  def partner_readonly?
    membership.role == Role.find_by(name: 'partner_readonly')
  end

  def member_or_admin?
    return true if record.user == user && !IdentityConfig.store.access_controls_enabled

    admin? || !!membership
  end

  def membership
    team = record.team
    team && UserTeam.find_by(team:, user:)
  end
end
