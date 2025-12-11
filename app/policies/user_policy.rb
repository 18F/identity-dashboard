class UserPolicy < BasePolicy # :nodoc:
  attr_reader :user

  def manage_users?
    user_has_login_admin_role?
  end

  def index?
    user_has_login_staff_role?
  end

  def none?
    true
  end

  def above_readonly_role?
    permitted_roles = Role::ROLES_NAMES - %w[logingov_readonly partner_readonly]
    permitted_roles.include? user.primary_role.name
  end

  # User policy scope
  class Scope < BasePolicy::Scope
    def resolve
      return scope if user_has_login_staff_role?

      # Rails can hand this off efficiently to the database
      user_ids_on_current_teams = TeamMembership.select(:user_id).where(team: user.teams)
      scope.where(id: user_ids_on_current_teams)
    end
  end
end
