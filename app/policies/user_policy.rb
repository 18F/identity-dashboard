class UserPolicy < BasePolicy
  attr_reader :user

  def manage_users?
    admin?
  end

  def none?
    true
  end

  private

  def admin?
    user&.admin?
  end
end
