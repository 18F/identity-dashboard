class ServiceProviderPolicy < BasePolicy
  attr_reader :user, :record

  def index?
    true
  end

  def show?
    member_or_admin?
  end

  def new?
    admin? || (membership && !partner_read_only?)
  end

  def edit?
    admin? || (membership && !partner_read_only?)
  end

  def create?
    admin? || (membership && !partner_read_only?)
  end

  def update?
    admin? || (membership && !partner_read_only?)
  end

  def destroy?
    member_or_admin?
  end

  def all?
    admin?
  end

  def deleted?
    admin?
  end

  def edit_custom_help_text?
    admin?
  end

  class Scope < BasePolicy::Scope
    def resolve
      return scope if admin?

      user.scoped_service_providers(scope:).reorder(nil)
    end
  end

  private

  def partner_read_only?
    membership.role == Role.find_by(name: 'Partner Readonly')
  end

  def member_or_admin?
    admin? || !!membership
  end

  def membership
    team = record.team
    team && UserTeam.find_by(team:, user:)
  end
end
