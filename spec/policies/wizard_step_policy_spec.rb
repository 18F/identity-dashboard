require 'rails_helper'

describe WizardStepPolicy do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:user) { build(:user) }
  let(:step_for_user) { build(:wizard_step, user:) }

  permissions :destroy? do
    it 'is allowed for all login.gov admins' do
      expect(WizardStepPolicy).to permit(logingov_admin, step_for_user)
    end

    it 'is allowed for the user who is creating the configuration' do
      expect(WizardStepPolicy).to permit(user, step_for_user)
    end

    it 'is forbidden for other users' do
      other_user = build(:user)
      expect(WizardStepPolicy).to_not permit(other_user, step_for_user)
    end
  end

  describe '#permitted_attributes' do
    it 'allows all except post-IdV URL for non-admin in not-prod' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      subject = described_class.new(user, WizardStep)
      expected_attributes = described_class::PARAMS.dup
      expected_attributes.delete :post_idv_follow_up_url
      expect(subject.permitted_attributes).to eq(expected_attributes)
    end

    it 'allows post-IdV URL too if the user can edit a config that already has the URL' do
      team = create(:team_membership, [:partner_developer, :partner_admin].sample, user:).team
      original_service_provider = create(
        :service_provider,
        post_idv_follow_up_url: "http://localhost:#{rand(1..9000)}",
        team: team,
      )
      wizard_step_from_sp = create(:wizard_step, step_name: 'hidden', user:, wizard_form_data: {
        service_provider_id: original_service_provider.id,
      })
      subject = described_class.new(user, wizard_step_from_sp)
      expect(subject.permitted_attributes).to eq(described_class::PARAMS.dup)
      expect(subject.permitted_attributes).to include(:ial)
      expect(subject.permitted_attributes).to include(:post_idv_follow_up_url)
    end

    context 'when in prod-like env' do
      before { allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true) }

      it 'allows all defaults for login.gov admin' do
        subject = described_class.new(logingov_admin, build(:wizard_step))
        expect(subject.permitted_attributes).to eq(described_class::PARAMS)
        expect(subject.permitted_attributes).to include(:ial)
        expect(subject.permitted_attributes).to include(:post_idv_follow_up_url)
      end

      it 'forbids editing IAL & post-IdV URL on editing existing configuration for non-admin' do
        editing_step = build(:wizard_step)
        existing_application = build(:service_provider, ial: 2)
        allow(editing_step).to receive(:existing_service_provider?).and_return true
        allow(editing_step).to receive(:original_service_provider).and_return existing_application
        subject = described_class.new(user, editing_step)
        expected_attributes = described_class::PARAMS.dup
        expected_attributes.delete :ial
        expected_attributes.delete :post_idv_follow_up_url
        expect(subject.permitted_attributes).to eq(expected_attributes)
      end

      it 'allows editing IAL but not post-IdV URL on new configuration for non-admin' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        subject = described_class.new(user, build(:wizard_step))
        expected_attributes = described_class::PARAMS.dup
        expected_attributes.delete(:post_idv_follow_up_url)
        expect(subject.permitted_attributes).to eq(expected_attributes)
      end
    end
  end
end
