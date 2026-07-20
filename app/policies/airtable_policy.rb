class AirtablePolicy < BasePolicy # :nodoc: all
  def index?
    prod_like = IdentityConfig.store.prod_like_env
    salesforce_disabled = !IdentityConfig.store.salesforce_api_enabled
    user_has_login_admin_role? && prod_like && salesforce_disabled
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
