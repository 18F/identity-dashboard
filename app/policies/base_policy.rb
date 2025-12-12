class BasePolicy # :nodoc: all
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.exists?(id: record.id)
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

    def user_has_login_staff_role?
      user&.logingov_staff?
    end
  end

  private

  def user_has_login_admin_role?
    user&.logingov_admin?
  end

  def user_has_login_staff_role?
    user&.logingov_staff?
  end

  def user_has_partner_admin_role?
    user.team_memberships.any? do |membership|
      membership.role == Role.find_by(name: 'partner_admin')
    end
  end

  def user_is_gov_partner?
    user&.gov_partner? && !user&.logingov_readonly?
  end
end
