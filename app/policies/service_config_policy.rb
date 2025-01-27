class ServiceConfigPolicy < BasePolicy
  def initialize(user, _placeholder)
    @user = user
  end

  def new?
    return true unless IdentityConfig.store.access_controls_enabled

    admin? || user.user_teams.any? do |membership|
      membership.role == Role.find_by(name: 'Partner Developer') ||
        membership.role == Role.find_by(name: 'Partner Admin')
    end
  end

  alias index? new?
  alias create? new?
  alias edit? new?
  alias show? new?
  alias update? new?
  alias destroy? new?
end
