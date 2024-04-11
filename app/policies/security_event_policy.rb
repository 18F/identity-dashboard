class SecurityEventPolicy < BasePolicy
  attr_reader :user, :record

  def manage_security_events?
    admin?
  end
end
