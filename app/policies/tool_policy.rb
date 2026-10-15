class ToolPolicy < BasePolicy # :nodoc:
  attr_reader :user, :record

  def can_view_request_details?
    user_has_login_admin_role? || in_team?
  end

  private

  def in_team?
    return false unless record.present?

    membership = record.team.team_memberships.find_by(user:)
    membership && membership.role_name != 'partner_reports_readonly'
  end
end
