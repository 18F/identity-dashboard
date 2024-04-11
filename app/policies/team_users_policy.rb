class TeamUsersPolicy < BasePolicy

  def manage_team_users?
    in_team? || admin?
  end

  private

  def in_team?
    record.users.include?(user)
  end
end
