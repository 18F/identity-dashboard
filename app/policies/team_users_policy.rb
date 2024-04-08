class TeamUsersPolicy < BasePolicy
  attr_reader :current_user, :team

  def initialize(current_user, team)
    @current_user = current_user
    @team = team
  end

  def manage?
    in_team? || admin?
  end

  private

  def admin?
    current_user&.admin?
  end

  def in_team?
    current_user.teams.include?(team)
  end
end
