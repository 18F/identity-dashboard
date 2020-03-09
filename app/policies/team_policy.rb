class TeamPolicy < BasePolicy
  attr_reader :current_user, :team

  WHITELISTED_DOMAINS = %w[.mil .gov .fed.us].freeze

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
    in_team? || admin?
  end

  def create?
    whitelisted_user? || admin?
  end

  def new?
    whitelisted_user? || admin?
  end

  private

  def admin?
    current_user&.admin?
  end

  def in_team?
    @team.users.include?(current_user)
  end

  def whitelisted_user?
    WHITELISTED_DOMAINS.any? { |domain| current_user.email.end_with? domain }
  end
end
