class ExtractPolicy < BasePolicy # :nodoc:
  attr_reader :user, :extract

  def index?
    admin_sandbox?
  end

  alias create? index?

  private

  def admin_sandbox?
    user_has_login_admin_role? && !IdentityConfig.store.prod_like_env
  end
end
