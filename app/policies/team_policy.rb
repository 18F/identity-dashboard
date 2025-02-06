class TeamPolicy < BasePolicy
  include TeamHelper

  def all?
    user_has_login_admin_role?
  end

  def create?
    user_has_login_admin_role? || user_has_partner_admin_role?
  end

  def destroy?
    user_has_login_admin_role?
  end

  def edit?
    user_has_login_admin_role? ||
      (in_team? && user_has_partner_admin_role?)
  end

  def index?
    true
  end

  def new?
    allowlisted_user?(user) || user_has_login_admin_role?
  end

  def show?
    in_team? || user_has_login_admin_role?
  end

  def update?
    user_has_login_admin_role? ||
      (in_team? && user_has_partner_admin_role?)
  end

  private

  def in_team?
    record.users.include?(user)
  end

  def user_has_login_admin_role?
    return admin? unless IdentityConfig.store.access_controls_enabled

    admin? || user.user_teams.any? do |membership|
      membership.role == Role.find_by(name: 'Login.gov Admin')
    end
  end

  def user_has_partner_admin_role?
    return true unless IdentityConfig.store.access_controls_enabled

    user.user_teams.any? do |membership|
      membership.role == Role.find_by(name: 'Partner Admin')
    end
  end
end
