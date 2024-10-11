require 'rails_helper'

describe WizardStepPolicy do
  let(:admin) { build(:user, admin: true)}
  let(:user) { build(:user)}
  let(:step_for_user) { build(:wizard_step, user: user) }

  permissions :destroy? do
    context 'with the feature flag' do
      before do
        expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(true)
      end
      
      it 'is true with the feature flag for all admins' do
        expect(WizardStepPolicy).to permit(admin, step_for_user)
      end
      it 'is true with the feature flag for the owning user' do
        expect(WizardStepPolicy).to permit(user, step_for_user)
      end
      it 'is false with the feature flag for other users' do
        other_user = build(:user)
        expect(WizardStepPolicy).to_not permit(other_user, step_for_user)
      end
    end

    context 'without the feature flag' do
      before do
        expect(IdentityConfig.store).to receive(:service_config_wizard_enabled).and_return(false)
      end

      it 'is false for the owning user' do
        expect(WizardStepPolicy).to_not permit(user, step_for_user)
      end
    end
  end
  
end
