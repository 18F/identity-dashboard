class TeamPolicy < BasePolicy
  include TeamHelper

  def all?
    admin?
  end

  def create?
    allowlisted_user?(user) || admin?
  end

  def destroy?
    admin?
  end

  def edit?
    in_team? || admin?
  end

  def index?
    true
  end

  def new?
    allowlisted_user?(user) || admin?
  end

  def show?
    in_team? || admin?
  end

  def update?
    in_team? || admin?
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if admin?

      scope.where(id: user.teams)
    end
  end

  private

  def in_team?
    record.users.include?(user)
  end
end
