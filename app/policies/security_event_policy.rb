class SecurityEventPolicy < BasePolicy # :nodoc:
  attr_reader :user, :record

  def manage_security_events?
    user_has_login_staff_role?
  end
end
