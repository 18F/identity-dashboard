# The InternalReports page is used for verifying TeamMemberships by issuer
# and is a security requirement
class InternalReportsController < AuthenticatedController
  before_action :admin_only

  def user_permissions
    sp_teams = ServiceProvider.left_joins(:team)
      .select(:id, :issuer, :group_id, :name, team: [:uuid])
      .where.not(group_id: nil)
    team_membership = TeamMembership.left_joins(:user, :role)
      .select(:id, :user_id, :email, :group_id, :role_name, roles: [:friendly_name])
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

    render renderable: UserPermissionsCsv.new(memberships)
  end

  private

  def admin_only
    raise AbstractController::ActionNotFound unless current_user.logingov_admin?
  end
end
