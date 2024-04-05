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
    login_engineer?
  end

  private

  def owner?
    sp.user == current_user
  end

  def login_engineer?
    current_user.login_engineer?
  end

  def member?
    sp.team.users.include?(current_user)
  end

  def member_or_admin?
    owner? || login_engineer? || member?
  end
end
