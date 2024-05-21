class BannerPolicy < BasePolicy
  def index?
    admin?
  end

  def create?
    admin?
  end

  def new?
    admin?
  end

  def show?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    false
  end

  class Scope < BasePolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.admin? ? scope.all : scope.none
    end
  end
end
