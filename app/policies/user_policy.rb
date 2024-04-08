class UserPolicy < BasePolicy
  attr_reader :current_user

  def initialize(current_user, _model)
    @current_user = current_user
  end

  def manage_users?
    current_user&.admin?
  end

  def none?
    true
  end
end
