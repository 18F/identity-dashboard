# Permission policy for Analytics dashboard
class AnalyticsPolicy < BasePolicy
  def index?
    IdentityConfig.store.prod_like_env && user_has_login_staff_role?
  end

  class Scope < BasePolicy::Scope # :nodoc:
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user_has_login_staff_role? ? scope.all : scope.none
    end
  end
end
