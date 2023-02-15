class TeamUsersPolicy < BasePolicy
  attr_reader :current_user, :team

  def initialize(current_user, team)
    @current_user = current_user
    @team = team
  end

  def index?
    in_team? || admin?
  end

  def new?
    in_team? || admin?
  end

  def create?
    in_team? || admin?
  end

  def remove_confirm?
    (admin? || in_team?) 
  end

  def destroy?
    (admin? || in_team?) 
  end

  private

  def admin?
    current_user&.admin?
  end

  def in_team?
    team.users.include?(current_user)
  end
end
