class SecurityEventPolicy < BasePolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @model = model
  end

  def manage_security_events?
    current_user&.admin?
  end

  def show?
    current_user&.admin?
  end
end
