class AnalyticsPolicy < BasePolicy
    def show?
      logingov_admin?
    end

    class Scope < BasePolicy::Scope
      # NOTE: Be explicit about which records you allow access to!
      def resolve
        user&.logingov_admin? ? scope.all : scope.none
      end
    end
  end