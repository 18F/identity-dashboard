class BasePolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(id: record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, 'BasePolicy::Scope#resolve should be overridden in a child class'
    end

    def user_has_login_admin_role?
      user&.logingov_admin?
    end
  end

  private

  def user_has_login_admin_role?
    user&.logingov_admin?
  end

  def user_has_partner_admin_role?
    return false unless IdentityConfig.store.access_controls_enabled

    user.user_teams.any? do |membership|
      membership.role == Role.find_by(name: 'partner_admin')
    end
  end
end
