class TeamPolicy < BasePolicy
  include TeamHelper

  def all?
    user_has_login_admin_role?
  end

  def create?
    (!IdentityConfig.store.access_controls_enabled && allowlisted_user?(user)) ||
      user_has_login_admin_role? || user_has_partner_admin_role?
  end

  def destroy?
    user_has_login_admin_role?
  end

  def edit?
    user_has_login_admin_role? ||
      (in_team? && !IdentityConfig.store.access_controls_enabled) ||
      user_has_partner_admin_role?
  end

  def index?
    true
  end

  def new?
    (!IdentityConfig.store.access_controls_enabled && allowlisted_user?(user)) ||
      user_has_login_admin_role? || user_has_partner_admin_role?
  end

  def show?
    in_team? || user_has_login_admin_role?
  end

  def update?
    user_has_login_admin_role? ||
      (in_team? && user_has_partner_admin_role?)
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if logingov_admin?

      scope.where(id: user.teams)
    end
  end

  private

  def in_team?
    record.users.include?(user)
  end
end
