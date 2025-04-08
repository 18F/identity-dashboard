class UserTeamPolicy < BasePolicy
  # TODO: remove `manage_team_users?` after turning on IdentityConfig.store.access_controls_enabled
  # and removing the flag
  def manage_team_users?
    unless IdentityConfig.store.access_controls_enabled
      return user_has_login_admin_role? || team_membership
    end

    create?
  end

  def index?
    user_has_login_admin_role? || team_membership && role_name != 'partner_readonly'
  end

  def create?
    user_has_login_admin_role? || role_name == 'partner_admin'
  end

  def edit?
    create? && record.user != user
  end

  alias update? edit?

  def new?
    create?
  end

  def destroy?
    return true if user_has_login_admin_role?

    edit?
  end

  def remove_confirm?
    if IdentityConfig.store.access_controls_enabled
      destroy?
    else
      manage_team_users? && record.user != user
    end
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if user_has_login_admin_role?

      scope.where(team: user.teams)
    end
  end

  private

  def team_membership
    @team_membership ||= record.team&.user_teams&.find_by(user:)
  end

  def role_name
    team_membership&.role&.name
  end
end
