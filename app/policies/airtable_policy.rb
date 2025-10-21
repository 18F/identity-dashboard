class AirtablePolicy < BasePolicy # :nodoc: all
  def index?
    user_has_login_admin_role?
  end

  alias oauth_redirect? index?
  alias refresh_token? index?
  alias clear_token? index?

  class Scope < BasePolicy::Scope
    def resolve
      user_has_login_admin_role? ? scope.where(user:) : scope.none
    end
  end
end
