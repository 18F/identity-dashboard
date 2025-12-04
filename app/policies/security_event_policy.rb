class SecurityEventPolicy < BasePolicy # :nodoc:
  attr_reader :user, :record

  def manage_security_events?
    user.logingov_staff?
  end
end
