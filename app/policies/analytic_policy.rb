# Permission policy for Analytics dashboard
class AnalyticPolicy < BasePolicy
  def index?
    return false unless user
    return true if user_has_login_admin_role?

    true if IdentityConfig.store.prod_like_env && user_has_login_staff_role?
  end

  # Analytic is not currently a db-backed model, so we can skip the Scope child class for now
end
