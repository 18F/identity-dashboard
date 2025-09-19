class ExtractPolicy < BasePolicy
  attr_reader :user, :extract

  PARAMS = %i[ticket search_by criteria_file criteria_list].freeze

  def permitted_attributes
    PARAMS
  end

  def index?
    is_admin_sandbox?
  end

  alias create? index?

  class Scope < BasePolicy::Scope
    def resolve
      scope if is_admin_sandbox?
    end
  end

  private

  def is_admin_sandbox?
    user_has_login_admin_role? && !IdentityConfig.store.prod_like_env
  end
end
