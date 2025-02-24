require 'rails_helper'

describe WizardStepPolicy do
  let(:admin) { build(:user, admin: true) }
  let(:user) { build(:user) }
  let(:step_for_user) { build(:wizard_step, user:) }

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

  describe '#permitted_attributes' do
    it 'allows base attributes for non-admin in not-prod' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      subject = described_class.new(user, WizardStep)
      expect(subject.permitted_attributes).to eq(described_class::PARAMS)
    end

    context 'when in prod-like env' do
      before { allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true) }

      it 'allows defaults for site admin' do
        subject = described_class.new(admin, build(:wizard_step))
        expect(subject.permitted_attributes).to eq(described_class::PARAMS)
      end

      it 'forbids IAL for non-admin editing existing config' do
        editing_step = build(:wizard_step)
        existing_application = build(:service_provider, ial: 2)
        allow(editing_step).to receive(:existing_service_provider?).and_return true
        allow(editing_step).to receive(:original_service_provider).and_return existing_application
        subject = described_class.new(user, editing_step)
        expected_attributes = described_class::PARAMS.reject { |param| param == :ial }
        expect(subject.permitted_attributes).to eq(expected_attributes)
      end

      it 'allows IAL for non-admin on new config' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        subject = described_class.new(user, build(:wizard_step))
        expect(subject.permitted_attributes).to eq(described_class::PARAMS)
      end
    end
  end
end
