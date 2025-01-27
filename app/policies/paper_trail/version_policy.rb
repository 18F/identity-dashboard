class PaperTrail::VersionPolicy < BasePolicy
  class Scope < BasePolicy::Scope
    def resolve
      admin? ? scope : scope.none
    end
  end
end
