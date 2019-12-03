class GroupPolicy < BasePolicy
  attr_reader :current_user, :group

  def initialize(current_user, model)
    @current_user = current_user
    @group = model
  end

  def index?
    true
  end

  def show?
    in_group? || admin?
  end

  def update?
    in_group? || admin?
  end

  def edit?
    in_group? || admin?
  end

  def destroy?
    admin?
  end

  def create?
    admin?
  end

  def new?
    admin?
  end

  private

  def admin?
    current_user&.admin?
  end

  def in_group?
    @group.users.include?(current_user)
  end
end
