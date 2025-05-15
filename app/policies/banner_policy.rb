class BannerPolicy < BasePolicy
  def manage_banners?
    user_has_login_admin_role?
  end

  def edit?
    return false if record.ended?

    user_has_login_admin_role?
  end

  class Scope < BasePolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user_has_login_admin_role? ? scope.all : scope.none
    end
  end
end
