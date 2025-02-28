class UserTeamPolicy < BasePolicy
  # TODO: remove `manage_team_users?` after turning on IdentityConfig.store.access_controls_enabled
  # and removing the flag
  def manage_team_users?
    return logingov_admin? || team_membership unless IdentityConfig.store.access_controls_enabled

    create?
  end

  def index?
    logingov_admin? || team_membership && role_name != 'partner_readonly'
  end

  def create?
    logingov_admin? || role_name == 'partner_admin'
  end

  def edit?
    create? && record.user != user
  end

  alias update? edit?

  def new?
    create?
  end

  def destroy?
    return true if logingov_admin?

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
      return scope if logingov_admin?

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
