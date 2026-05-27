# Permission policy for Analytics dashboard
class AnalyticPolicy < BasePolicy
  def index?
    return false unless user

    true
  end

  def create?
    index?
  end

  # Analytic is not currently a db-backed model, so we can skip the Scope child class for now
end
