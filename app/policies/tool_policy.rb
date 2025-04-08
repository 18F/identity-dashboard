class ToolPolicy < BasePolicy
  attr_reader :user, :record

  def can_view_request_details?
    user_has_login_admin_role? || in_team?
  end

  private

  def in_team?
    return false unless record.present?

    record.team.users.include?(user)
  end
end
