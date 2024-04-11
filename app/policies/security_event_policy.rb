class SecurityEventPolicy < BasePolicy
  attr_reader :user, :record

  def manage_security_events?
    user&.admin?
  end
end
