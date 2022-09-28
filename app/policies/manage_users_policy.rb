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
    admin? || (in_team? && user_to_delete_in_team?)
  end

  private

  def user_to_delete_in_team?
    team.users.include?(params[:id])
  end 

  def admin?
    current_user&.admin?
  end

  def in_team?
    team.users.include?(current_user)
  end
end
