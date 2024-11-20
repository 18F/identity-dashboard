class UserTeamPolicy < BasePolicy

  def manage_team_users?
    admin? || in_team?
  end

  def create?
    
  end

  private

  def in_team?
    record.users.include?(user)
  end
end
