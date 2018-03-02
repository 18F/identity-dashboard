class UserPolicy < BasePolicy
  attr_reader :current_user

  def initialize(current_user, _model)
    @current_user = current_user
  end

  def index?
    admin?
  end

  def update?
    admin?
  end

  def edit?
    admin?
  end

  def none?
    true
  end

  private

  def admin?
    current_user && current_user.admin?
  end
end
