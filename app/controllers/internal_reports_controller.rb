# The InternalReports page is used for verifying TeamMemberships by issuer
# and is a security requirement
class InternalReportsController < AuthenticatedController
  before_action :admin_only

  # @return [Array<Hash>]
  #   * :issuer [String] ServiceProvider instance issuer
  #   * :team_uuid [UUID] Team instance UUID
  #   * :team_name [String] Team instance Id
  #   * :user_email [String] User instance email address
  #   * :role [String] TeamMembership instance Role friendly_name
  def user_permissions
    sp_teams = ServiceProvider.left_joins(:team)
      .select(:id, :issuer, :group_id, :name, team: [:uuid])
      .where.not(group_id: nil)
    team_membership = TeamMembership.left_joins(:user, :role)
      .select(:id, :user_id, :email, :group_id, roles: [:friendly_name])
    memberships = []
    sp_teams.each do |spt|
      spt_membership = team_membership.where(group_id: spt.group_id)
      spt_membership.each do |sptm|
        memberships.push({
          issuer: spt.issuer,
          team_uuid: spt.uuid,
          team_name: spt.name,
          user_email: sptm.email,
          role: sptm.friendly_name,
        })
      end
    end

    render renderable: UserPermissionsCsv.new(memberships.union(internal_team_roles))
  end

  private

  def admin_only
    raise AbstractController::ActionNotFound unless current_user.logingov_admin?
  end
  # We need to include `logingov_admin` roles in our report
  # @return [Array<Hash>] of the same shape as `user_permissions`
  def internal_team_roles
    internal_memberships = TeamMembership.left_joins(:team, :user, :role)
      .select(:email, role: [:friendly_name], team: [:uuid, :name])
      .where(group_id: Team.internal_team.id)
    # Issuer is not particularly relevant for the Internal Team, and
    # we don't have any at the moment.
    internal_memberships.map do |membership|
      {
        issuer: '',
        team_uuid: membership.uuid,
        team_name: membership.name,
        user_email: membership.email,
        role: membership.friendly_name,
      }
    end
  end
end
