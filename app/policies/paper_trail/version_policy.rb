class PaperTrail::VersionPolicy < BasePolicy
  class Scope < BasePolicy::Scope
    def resolve
      admin? ? scope : scope.none
    end
  end

  def can_view_papertrail?
    return false unless IdentityConfig.store.access_controls_enabled
    admin? || user.user_teams.any? do |membership|
      membership.role == Role.find_by(name: 'Partner Developer') ||
        membership.role == Role.find_by(name: 'Partner Admin')
    end
  end
end