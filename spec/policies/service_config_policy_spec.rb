require 'rails_helper'

describe ServiceConfigPolicy do
  let(:logingov_admin) { create(:logingov_admin) }
  let(:team) { create(:team) }
  let(:partner_admin) { create(:user_team, :partner_admin, team:).user }
  let(:partner_developer) { create(:user_team, :partner_developer, team:).user }
  let(:partner_readonly) { create(:user_team, :partner_readonly, team:).user }
  let(:non_team_member) { create(:restricted_ic) }
  let(:object) { WizardStep.new }

  shared_examples_for 'allows all team members except Partner Readonly for `object`' do
    it 'forbids Partner Readonly' do
      expect(described_class).to_not permit(partner_readonly, object)
    end

    it 'forbids non-team-member users' do
      expect(described_class).to_not permit(non_team_member, object)
    end

    it 'allows login.gov admin' do
      expect(described_class).to permit(logingov_admin, object)
    end

    it 'allows Partner Admin' do
      expect(described_class).to permit(partner_admin, object)
    end

    it 'allows Partner Developer' do
      expect(described_class).to permit(partner_developer, object)
    end
  end

  permissions :new? do
    it_behaves_like 'allows all team members except Partner Readonly for `object`'
  end

  %i[index? create? edit? show? update? destroy?].each do |action_alias|
    context 'with RBAC' do
      before do
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return true
      end

      permissions action_alias do
        it_behaves_like 'allows all team members except Partner Readonly for `object`'
      end
    end

    context 'without RBAC' do
      before do
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return false
      end

      permissions action_alias do
        it 'allows anyone' do
          expect(described_class).to permit(build(:user))
        end
      end
    end
  end
end
