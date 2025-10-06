class PaperTrail::VersionPolicy < BasePolicy # :nodoc:
  class Scope < BasePolicy::Scope # :nodoc:
    def resolve
      user_has_login_admin_role? ? scope : scope.none
    end
  end

  def can_view_papertrail?
    return user_has_login_admin_role? unless IdentityConfig.store.access_controls_enabled

    user_has_login_admin_role? || user.team_memberships.any? do |membership|
      membership.role == Role.find_by(name: 'Partner Developer') ||
        membership.role == Role.find_by(name: 'Partner Admin')
    end
  end
end
