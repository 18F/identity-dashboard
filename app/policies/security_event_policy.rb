class SecurityEventPolicy < BasePolicy
  attr_reader :user, :record

  def manage_security_events?
    user_has_login_admin_role?
  end
end
