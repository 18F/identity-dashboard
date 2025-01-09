class BannerPolicy < BasePolicy
  def manage_banners?
    admin?
  end

  def edit?
    return false if record.ended? 

    admin?
  end

  class Scope < BasePolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user&.admin? ? scope.all : scope.none
    end
  end
end
