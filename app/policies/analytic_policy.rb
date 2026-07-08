# Permission policy for Analytics dashboard
class AnalyticPolicy < BasePolicy
  def index?
    return false unless user

    user.logingov_staff? || user.team_memberships.exists?(role_name: 'partner_admin')
  end

  def fetch?
    index?
  end

  # Analytic is not currently a db-backed model, so we can skip the Scope child class for now
end
