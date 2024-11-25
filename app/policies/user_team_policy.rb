class UserTeamPolicy < BasePolicy

  def manage_team_users?
    admin? || user_team_role
  end

  def index?
    admin? || user_team_role && user_team_role.name != 'Partner Readonly'
  end

  def create?
    admin? || user_team_role && user_team_role.name == 'Partner Admin'
  end

  def new?
    create?
  end

  def destroy?
    return true if admin?
    record.user != user && create?
  end

  def remove_confirm?
    destroy?
  end

  private

  def user_team_role
    @user_user_team ||= record.team && record.team.user_teams.find_by(user: user)
    if IdentityConfig.store.access_controls_enabled
      @user_user_team&.role
    else
      @user_user_team
    end
  end
end
