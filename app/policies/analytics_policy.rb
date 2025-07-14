# Permission policy for Analytics dashboard
class AnalyticsPolicy < BasePolicy
  def show?
    user_has_login_admin_role?
  end

  def stream_daily_auths_report?
      user.present?
  end

  class Scope < BasePolicy::Scope # :nodoc:
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user_has_login_admin_role? ? scope.all : scope.none
    end
  end
end
