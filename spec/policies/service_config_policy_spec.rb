require 'rails_helper'

describe ServiceConfigPolicy do
  let(:logingov_admin) { create(:logingov_admin) }
  let(:team) { create(:team) }
  let(:partner_admin) { create(:team_membership, :partner_admin, team:).user }
  let(:partner_developer) { create(:team_membership, :partner_developer, team:).user }
  let(:partner_readonly) { create(:team_membership, :partner_readonly, team:).user }
  let(:user_not_on_team) { create(:restricted_ic) }
  let(:object) { WizardStep.new }

  shared_examples_for 'allows all team members except Partner Readonly for `object`' do
    it 'forbids Partner Readonly' do
      expect(described_class).to_not permit(partner_readonly, object)
    end

    it 'forbids non-team-member users' do
      expect(described_class).to_not permit(user_not_on_team, object)
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
    permissions action_alias do
      it_behaves_like 'allows all team members except Partner Readonly for `object`'
    end
  end
end
