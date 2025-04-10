class UserPolicy < BasePolicy
  attr_reader :user

  def manage_users?
    user_has_login_admin_role?
  end

  def none?
    true
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if user_has_login_admin_role?

      # Rails can hand this off efficiently to the database
      user_ids_on_current_teams = UserTeam.select(:user_id).where(team: user.teams)
      scope.where(id: user_ids_on_current_teams)
    end
  end
end
