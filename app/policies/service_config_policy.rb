class ServiceConfigPolicy < BasePolicy
  def initialize(user, _placeholder)
    @user = user
  end

  def new?
    admin?
  end
  alias index? new?
  alias create? new?
  alias edit? new?
  alias show? new?
  alias update? new?
  alias destroy? new?
end
