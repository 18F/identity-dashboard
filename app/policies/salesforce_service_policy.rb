class SalesforceServicePolicy < BasePolicy # :nodoc: all
  def index?
    user_has_login_admin_role? && prod_like_env?
  end

  def prod_like_env?
    IdentityConfig.store.prod_like_env
  end
end
