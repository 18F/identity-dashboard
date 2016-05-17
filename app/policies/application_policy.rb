class ApplicationPolicy < BasePolicy
  attr_reader :current_user, :app

  def initialize(current_user, model)
    @current_user = current_user
    @app = model
  end

  def index?
    true
  end

  def show?
    owner_or_admin?
  end

  def update?
    owner_or_admin?
  end

  def edit?
    owner_or_admin?
  end

  def destroy?
    owner_or_admin?
  end

  def create?
    true
  end

  def new?
    true
  end

  private

  def owner?
    app.user == current_user
  end

  def admin?
    current_user.admin?
  end

  def owner_or_admin?
    owner? || admin?
  end
end
