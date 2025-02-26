class AuthTokenPolicy < BasePolicy
  def index?
    user_has_login_admin_role?
  end

  alias show? index?
  alias new? index?
  alias create? index?

  class Scope < BasePolicy::Scope
    def resolve
      logingov_admin? ? scope.where(user:) : scope.none
    end
  end
end
