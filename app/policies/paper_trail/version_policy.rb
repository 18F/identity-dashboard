class PaperTrail::VersionPolicy < BasePolicy
  class Scope < BasePolicy::Scope
    def resolve
      user&.admin? ? scope.all : scope.none
    end
  end
end
