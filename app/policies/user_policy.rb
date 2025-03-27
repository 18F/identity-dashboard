class UserPolicy < BasePolicy
  attr_reader :user

  def manage_users?
    logingov_admin?
  end

  def none?
    true
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if logingov_admin?

      # Rails can hand this off efficiently to the database
      user_ids_on_current_teams = UserTeam.select(:user_id).where(team: user.teams)
      scope.where(id: user_ids_on_current_teams)
    end
  end
end
