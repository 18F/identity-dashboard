class SalesforcePolicy < BasePolicy # :nodoc: all
  def index?
    user_has_login_admin_role? && prod_like_env? && salesforce_enabled?
  end

  def prod_like_env?
    IdentityConfig.store.prod_like_env
  end

  def salesforce_enabled?
    IdentityConfig.store.salesforce_api_enabled
  end
end
