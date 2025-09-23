class ExtractPolicy < BasePolicy
  attr_reader :user, :extract

  def index?
    is_admin_sandbox?
  end

  alias create? index?

  private

  def is_admin_sandbox?
    user_has_login_admin_role? && !IdentityConfig.store.prod_like_env
  end
end
