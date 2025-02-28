class BannerPolicy < BasePolicy
  def manage_banners?
    logingov_admin?
  end

  def edit?
    return false if record.ended?

    logingov_admin?
  end

  class Scope < BasePolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user&.logingov_admin? ? scope.all : scope.none
    end
  end
end
