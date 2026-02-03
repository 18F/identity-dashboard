class TeamPolicy < BasePolicy # :nodoc: all
  include TeamHelper

  def all?
    user_has_login_staff_role?
  end

  def create?
    return user_has_login_admin_role? if IdentityConfig.store.prod_like_env

    user_has_login_admin_role? || user_is_gov_partner?
  end

  def destroy?
    return user_has_login_admin_role? if IdentityConfig.store.prod_like_env

    edit?
  end

  def edit?
    user_has_login_admin_role? || (team_membership && team_membership.role_name == 'partner_admin')
  end

  def index?
    true
  end

  def new?
    return user_has_login_admin_role? if IdentityConfig.store.prod_like_env

    user_has_login_admin_role? || user_is_gov_partner?
  end

  def show?
    in_team? || user_has_login_staff_role?
  end

  alias update? edit?

  def manage_users?
    edit? || user.logingov_readonly?
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if user_has_login_staff_role?

      scope.where(id: user.teams)
    end
  end

  private

  def team_membership
    record && record.class != Class && TeamMembership.find_by(team: record, user: user)
  end

  def in_team?
    record.users.include?(user)
  end
end
