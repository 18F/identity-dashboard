# Permission policy for ServiceConfigWizard (Guided Flow)
class ServiceConfigPolicy < BasePolicy
  def initialize(user, _placeholder)
    @user = user
  end

  def new?
    user_has_login_admin_role? || user.team_memberships.any? do |membership|
      membership.role == Role.find_by(name: 'partner_developer') ||
        membership.role == Role.find_by(name: 'partner_admin')
    end
  end

  alias index? new?
  alias create? new?
  alias edit? new?
  alias show? new?
  alias update? new?
  alias destroy? new?
end
