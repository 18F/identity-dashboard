# Permission policy for PaperTrail logs
class PaperTrail::VersionPolicy < BasePolicy
  # Policy scope for Papertrail logs
  class Scope < BasePolicy::Scope
    def resolve
      user_has_login_admin_role? ? scope : scope.none
    end
  end

  def can_view_papertrail?
    user_has_login_admin_role?
  end
end
