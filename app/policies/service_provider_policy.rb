class ServiceProviderPolicy < BasePolicy
  attr_reader :current_user, :sp

  def initialize(current_user, model)
    @current_user = current_user
    @sp = model
  end

  def index?
    true
  end

  def show?
    member_or_admin?
  end

  def update?
    member_or_admin?
  end

  def edit?
    member_or_admin?
  end

  def destroy?
    member_or_admin?
  end

  def create?
    true
  end

  def new?
    true
  end

  def all?
    admin?
  end

  private

  def owner?
    sp.user == current_user
  end

  def admin?
    current_user.admin?
  end

  def member?
    sp.group.present? && current_user.groups.include?(sp.group)
  end

  def member_or_admin?
    owner? || admin? || member?
  end
end
