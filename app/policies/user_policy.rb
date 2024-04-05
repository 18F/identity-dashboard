class UserPolicy < BasePolicy
  attr_reader :current_user

  def initialize(current_user, _model)
    @current_user = current_user
  end

  def login_engineer?
    current_user&.login_engineer?
  end

  def none?
    true
  end
end
