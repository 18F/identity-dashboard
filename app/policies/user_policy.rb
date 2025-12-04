class UserPolicy < BasePolicy # :nodoc:
  attr_reader :user

  def manage_users?
    user_has_login_admin_role?
  end

  def view_users?
    user.logingov_staff?
  end

  def none?
    true
  end

  # User policy scope
  class Scope < BasePolicy::Scope
    def resolve
      return scope if user.logingov_staff?

      # Rails can hand this off efficiently to the database
      user_ids_on_current_teams = TeamMembership.select(:user_id).where(team: user.teams)
      scope.where(id: user_ids_on_current_teams)
    end
  end
end
