# Permission policy for Analytics dashboard
class AnalyticPolicy < BasePolicy
  def index?
    return false unless user

    IdentityConfig.store.prod_like_env && user_has_login_admin_role?
  end

  class Scope < BasePolicy::Scope # :nodoc:
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user_has_login_admin_role? ? scope.all : scope.none
    end
  end
end
