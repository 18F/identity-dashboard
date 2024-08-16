class WizardStepPolicy < BasePolicy
  class Scope < BasePolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end