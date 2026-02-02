# The InternalReports page is used for verifying TeamMemberships by issuer
# and is a security requirement
class InternalReportsController < AuthenticatedController
  before_action :staff_only

  # Return hash shape is
  #
  #   * :issuer [String] ServiceProvider instance issuer
  #   * :team_uuid [UUID] Team instance UUID
  #   * :team_name [String] Team instance Id
  #   * :user_email [String] User instance email address
  #   * :role [String] TeamMembership instance Role.friendly_name
  # @return [Array<Hash>]
  def user_permissions
    memberships = []

    service_provider_teams.each do |spt|
      spt_membership = team_memberships.where(group_id: spt.group_id)
      spt_membership.each do |spt_m|
        memberships.push({
          issuer: spt.issuer,
          team_uuid: spt.uuid,
          team_name: spt.name,
          user_email: spt_m.email,
          role: Role.active_roles_names[spt_m.name],
        })
      end
    end

    all_members = (memberships + internal_team_roles + users_without_team_memberships)
    permissions_array = all_members.sort_by do |entry|
      [entry[:issuer].to_s, entry[:user_email].to_s]
    end

    render renderable: UserPermissionsCsv.new(permissions_array)
  end

  private

  # @return [ActionNotFound, nil] raises error if not logingov_admin or _readonly
  def staff_only
    raise AbstractController::ActionNotFound unless current_user.logingov_staff?
  end

  # @return [Array<ServiceProvider, Team>] Joins ServiceProvider issuer with
  # Team group_id, name, and uuid
  def service_provider_teams
    @service_provider_teams ||= ServiceProvider.left_joins(:team)
      .select(:id, :issuer, :group_id, :name, team: [:uuid])
      .where.not(group_id: nil)
  end

  # @return [Array<TeamMembership, User, Role>] Joins TeamMembership group_id
  # with User email and Role name
  def team_memberships
    @team_memberships ||= TeamMembership.left_joins(:user, :role)
      .select(:id, :email, :group_id, roles: [:name])
  end

  # We need to include `logingov_admin` roles in our report
  # @return [Array<Hash>] of the same shape as `user_permissions`
  def internal_team_roles
    internal_memberships = TeamMembership.left_joins(:team, :user)
      .select(:email, :role_name, team: [:uuid, :name])
      .where(group_id: Team.internal_team.id)
    # Issuer is not particularly relevant for the Internal Team, and
    # we don't have any at the moment.
    internal_memberships.map do |membership|
      {
        issuer: '',
        team_uuid: membership.uuid,
        team_name: membership.name,
        user_email: membership.email,
        role: Role.active_roles_names[membership.role_name],
      }
    end
  end

  # Users with no team memberships
  # @return [Array<Hash>] of the same shape as `user_permissions`
  def users_without_team_memberships
    User.where.missing(:team_memberships)
      .pluck(:email)
      .map do |email|
        {
          issuer: '',
          team_uuid: '',
          team_name: '',
          user_email: email,
          role: '',
        }
      end
  end
end
