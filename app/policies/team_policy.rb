class TeamPolicy < BasePolicy
  include TeamHelper

  attr_reader :current_user, :team

  def initialize(current_user, model)
    @current_user = current_user
    @team = model
  end

  def index?
    true
  end

  def show?
    in_team? || admin?
  end

  def update?
    in_team? || admin?
  end

  def edit?
    in_team? || admin?
  end

  def destroy?
    admin?
  end

  def create?
    allowlisted_user?(current_user) || admin?
  end

  def new?
    allowlisted_user?(current_user) || admin?
  end

  def all?
    admin?
  end

  private

  def admin?
    current_user&.admin?
  end

  def in_team?
    @team.users.include?(current_user)
  end
end
