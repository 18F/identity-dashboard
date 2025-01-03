class UserTeamPolicy < BasePolicy
  # TODO: remove `manage_team_users?` after turning on IdentityConfig.store.access_controls_enabled
  # and removing the flag
  def manage_team_users?
    return admin? || team_membership unless IdentityConfig.store.access_controls_enabled

    create?
  end

  def index?
    admin? || team_membership && role_name != 'Partner Readonly'
  end

  def create?
    admin? || role_name == 'Partner Admin'
  end

  def new?
    create?
  end

  def destroy?
    return true if admin?

    record.user != user && create?
  end

  def remove_confirm?
    if IdentityConfig.store.access_controls_enabled
      destroy?
    else
      manage_team_users? && record.user != user
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
