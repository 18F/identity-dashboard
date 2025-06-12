class InternalReportsController < AuthenticatedController
  before_action :admin_only

  def memberships
    memberships = UserTeam.left_joins(:user, :role)
      .select(:id, :user_id, :group_id, :role_name, roles: [:friendly_name])
      .order('users.email', 'roles.id', :group_id)

    render renderable: MembershipCsv.new(memberships)
  end

  private

  def admin_only
    raise AbstractController::ActionNotFound unless current_user.logingov_admin?
  end
end
