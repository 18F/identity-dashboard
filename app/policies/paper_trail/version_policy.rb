class PaperTrail::VersionPolicy < BasePolicy
  class Scope < BasePolicy::Scope
    def resolve
      logingov_admin? ? scope : scope.none
    end
  end

  def can_view_papertrail?
    return logingov_admin? unless IdentityConfig.store.access_controls_enabled

    logingov_admin? || user.user_teams.any? do |membership|
      membership.role == Role.find_by(name: 'Partner Developer') ||
        membership.role == Role.find_by(name: 'Partner Admin')
    end
  end
end
