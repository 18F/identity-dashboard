class TeamPolicy < BasePolicy
  include TeamHelper

  def all?
    user_has_login_admin_role?
  end

  def create?
    return user_has_login_admin_role? if IdentityConfig.store.prod_like_env
    unless IdentityConfig.store.access_controls_enabled
      return allowlisted_user?(user) || user_has_login_admin_role?
    end

    user_has_login_admin_role? || user_has_partner_admin_role?
  end

  def destroy?
    user_has_login_admin_role?
  end

  def edit?
    unless IdentityConfig.store.access_controls_enabled
      return in_team? || user_has_login_admin_role?
    end

    user_has_login_admin_role? || ( membership && membership.role_name == 'partner_admin')
  end

  def index?
    true
  end

  def new?
    return user_has_login_admin_role? if IdentityConfig.store.prod_like_env
    unless IdentityConfig.store.access_controls_enabled
      return allowlisted_user?(user) || user_has_login_admin_role?
    end

    user_has_login_admin_role? || user_has_partner_admin_role?
  end

  def show?
    in_team? || user_has_login_admin_role?
  end

  alias update? edit?

  class Scope < BasePolicy::Scope
    def resolve
      return scope if user_has_login_admin_role?

      scope.where(id: user.teams)
    end
  end

  private

  def membership
    record && record.class != Class && UserTeam.find_by(team: record, user: user)
  end

  def in_team?
    record.users.include?(user)
  end
end
