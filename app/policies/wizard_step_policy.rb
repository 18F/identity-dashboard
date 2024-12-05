class WizardStepPolicy < BasePolicy
  def destroy?
    IdentityConfig.store.service_config_wizard_enabled && (user.admin? || record.user == user)
  end

  class Scope < BasePolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
