# The InternalReports page is used for verifying TeamMemberships by issuer
# and is a security requirement
class InternalReportsController < AuthenticatedController
  before_action :admin_only

  def issuer_memberships
    sp_teams = ServiceProvider.left_joins(:team)
      .select(:id, :issuer, :group_id, :name, team: [:uuid])
      .where.not(group_id: nil)
    team_membership = TeamMembership.left_joins(:user, :role)
      .select(:id, :user_id, :email, :group_id, :role_name, roles: [:friendly_name])
    memberships = sp_teams.map do |spt|
      spt_membership = team_membership.find_by(group_id: spt.group_id)
      {
        issuer: spt.issuer,
        team_uuid: spt.uuid,
        team_name: spt.name,
        user_email: spt_membership.email,
        role: spt_membership.friendly_name,
      }
    end

    render renderable: IssuerMembershipCsv.new(memberships)
  end

  private

  def admin_only
    raise AbstractController::ActionNotFound unless current_user.logingov_admin?
  end
end
