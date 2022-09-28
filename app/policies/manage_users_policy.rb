class ManageUsersPolicy < BasePolicy
  attr_reader :current_user, :team

  def initialize(current_user, team)
    @current_user = current_user
    @team = team
  end

  def new?
    in_team? || admin?
  end

  def create?
    in_team? || admin?
  end

  def delete?
    in_team? || admin?
  end

  def destroy?
    in_team? || admin?
  end

  private

  def admin?
    current_user&.admin?
  end

  def in_team?
    team.users.include?(current_user)
  end
end
