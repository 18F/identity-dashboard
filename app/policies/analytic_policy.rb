# Permission policy for Analytics dashboard
class AnalyticPolicy < BasePolicy
  def index?
    return false unless user

    true if user_has_login_admin_role?
  end

  def download?
    return false unless user

    true if user_has_login_admin_role?
  end

  # Analytic is not currently a db-backed model, so we can skip the Scope child class for now
end
