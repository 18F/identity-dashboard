class BannerPolicy < BasePolicy # :nodoc: all
  def manage_banners?
    user_has_login_admin_role?
  end

  def view_banners?
    user&.logingov_staff?
  end

  def edit?
    return false if record.ended?

    user_has_login_admin_role?
  end

  class Scope < BasePolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.logingov_staff? ? scope.all : scope.none
    end
  end
end
