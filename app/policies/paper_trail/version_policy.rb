# Permission policy for PaperTrail logs
class PaperTrail::VersionPolicy < BasePolicy
  # Policy scope for Papertrail logs
  class Scope < BasePolicy::Scope
    def resolve
      user.logingov_staff? ? scope : scope.none
    end
  end

  def can_view_papertrail?
    user.logingov_staff?
  end
end
