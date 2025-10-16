# The InternalReports page is used for verifying TeamMemberships and is a
# security requirement
class InternalReportsController < AuthenticatedController
  before_action :admin_only

  def team_memberships
    team_memberships = TeamMembership.left_joins(:user, :role)
      .select(:id, :user_id, :group_id, :role_name, roles: [:friendly_name])
      .order('users.email', 'roles.id', :group_id)

    render renderable: TeamMembershipCsv.new(team_memberships)
  end

  private

  def admin_only
    raise AbstractController::ActionNotFound unless current_user.logingov_admin?
  end
end
