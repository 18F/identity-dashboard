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
    in_team? || login_engineer?
  end

  def update?
    in_team? || login_engineer?
  end

  def edit?
    in_team? || login_engineer?
  end

  def destroy?
    login_engineer?
  end

  def create?
    !restricted_ic?
  end

  def new?
    !restricted_ic?
  end

  def all?
    login_engineer?
  end

  private
  def login_engineer?
    current_user&.login_engineer?
  end

  def restricted_ic?
    current_user.restricted_ic?
  end

  def in_team?
    @team.users.include?(current_user)
  end
end
