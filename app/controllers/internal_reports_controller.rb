# The InternalReports page is used for verifying TeamMemberships by issuer
# and is a security requirement
class InternalReportsController < AuthenticatedController
  before_action :staff_only

  # Return data schema is
  #
  #   * :issuer [String] ServiceProvider instance issuer (empty for internal roles)
  #   * :team_uuid [UUID] Team instance UUID
  #   * :team_name [String] Team instance Id
  #   * :user_email [String] User instance email address
  #   * :role [String] TeamMembership instance Role.friendly_name
  def user_permissions
    data = sort_data(collect_memberships)

    render renderable: UserPermissionsCsv.new(data)
  end

  private

  # @return [ActionNotFound, nil] raises error if not logingov_admin or _readonly
  def staff_only
    raise AbstractController::ActionNotFound unless current_user.logingov_staff?
  end

  def collect_memberships
    internal_membership_data.union(service_provider_membership_data)
  end

  def internal_membership_data
    TeamMembership.left_joins(:team, :user)
      .select(:email, :role_name, team: [:uuid, :name])
      .where(group_id: Team.internal_team.id).map do |membership|
        {
          issuer: '',
          team_uuid: membership.uuid,
          team_name: membership.name,
          user_email: membership.email,
          role: Role.active_roles_names[membership.role_name],
        }
      end
  end

  def service_provider_membership_data
    service_provider_teams.flat_map do |sp_team|
      team_memberships.where(group_id: sp_team.group_id).map do |membership|
        {
          issuer: sp_team.issuer,
          team_uuid: sp_team.uuid,
          team_name: sp_team.name,
          user_email: membership.email,
          role: Role.active_roles_names[membership.name],
        }
      end
    end
  end

  # Joins ServiceProvider id and issuer attributes with
  # Team group_id, name, and uuid attributes
  def service_provider_teams
    @service_provider_teams ||= ServiceProvider.left_joins(:team)
      .select(:id, :issuer, :group_id, :name, team: [:uuid])
      .where.not(group_id: nil)
  end

  # Joins TeamMembership id and group_id with User email and Role name.
  # Left join allows email and role to be nil when the team has no members.
  def team_memberships
    @team_memberships ||= TeamMembership.left_joins(:user, :role)
      .select(:id, :email, :group_id, roles: [:name])
  end

  def sort_data(collection)
    collection.sort do |a, b|
      [a[:issuer], a[:user_email]] <=> [b[:issuer], b[:user_email]]
    end
  end
end
