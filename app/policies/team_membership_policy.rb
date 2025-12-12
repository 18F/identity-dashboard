class TeamMembershipPolicy < BasePolicy # :nodoc: all
  def index?
    user_has_login_staff_role? || team_membership && current_user_role_on_team != 'partner_readonly'
  end

  def create?
    user_has_login_admin_role? || not_internal_team? && current_user_role_on_team == 'partner_admin'
  end

  def edit?
    create? && record.user != user
  end

  def update?
    return false unless edit?

    true if user_has_login_admin_role? || roles_for_edit.include?(record.role)
  end

  def new?
    create?
  end

  def destroy?
    return true if user_has_login_admin_role?

    edit?
  end

  def remove_confirm?
    destroy?
  end

  def roles_for_edit
    return Role.none unless edit?
    return Role.where.not(name: [:logingov_admin, :logingov_readonly]) if user_has_login_admin_role?

    Role.where.not(name: %i[logingov_admin logingov_readonly partner_admin])
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if user_has_login_staff_role?

      scope.where(team: user.teams)
    end
  end

  private

  def team_membership
    @team_membership ||= record.team&.team_memberships&.find_by(user:)
  end

  def current_user_role_on_team
    team_membership&.role&.name
  end

  def not_internal_team?
    team_membership && team_membership.team != Team.internal_team
  end
end
