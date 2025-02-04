require 'rails_helper'

describe UserTeamPolicy do
  let(:team) { create(:team) }
  let(:partner_admin_membership) { create(:user_team, :partner_admin, team:) }
  let(:partner_developer_membership) { create(:user_team, :partner_developer, team:) }
  let(:partner_readonly_membership) { create(:user_team, :partner_readonly, team:) }
  let(:partner_admin) { partner_admin_membership.user }
  let(:partner_developer) { partner_developer_membership.user }
  let(:partner_readonly) { partner_readonly_membership.user }
  let(:logingov_admin) { build(:logingov_admin) }
  let(:other_user) { build(:restricted_ic) }
  let(:without_role_membership) { create(:user_team) }

  permissions :manage_team_users? do
    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).at_most(1).and_return(false)
    end

    it 'allows team member to manage team users' do
      expect(described_class).to permit(without_role_membership.user, without_role_membership)
    end

    it 'allows login.gov admin to manage team users' do
      expect(described_class).to permit(logingov_admin, without_role_membership)
    end

    it 'does not allow a random user to manage team users' do
      expect(described_class).to_not permit(other_user, without_role_membership)
    end
  end

  permissions :index? do
    it 'allows Partner Admins' do
      expect(described_class).to permit(partner_admin, partner_admin_membership)
    end

    it 'allows Partner Developers' do
      expect(described_class).to permit(partner_developer, partner_developer_membership)
    end

    it 'forbids Partner Readonly' do
      expect(described_class).to_not permit(partner_readonly, partner_readonly_membership)
    end
  end

  permissions :create? do
    it 'allows Partner Admins' do
      new_membership = partner_admin_membership.team.user_teams.build
      expect(described_class).to permit(partner_admin, new_membership)
    end

    it 'forbids Partner Developers' do
      new_membership = partner_developer_membership.team.user_teams.build
      expect(described_class).to_not permit(partner_developer, new_membership)
    end

    it 'forbids Partner Readonly' do
      new_membership = partner_readonly_membership.team.user_teams.build
      expect(described_class).to_not permit(partner_readonly, new_membership)
    end
  end

  permissions :edit? do
    it 'allows Login Admins' do
      expect(described_class).to permit(logingov_admin, partner_admin_membership)
    end

    it 'allows Partner Admins' do
      new_membership = team.user_teams.build
      expect(described_class).to permit(partner_admin, new_membership)
    end

    it 'forbids Partner Admins for own memberships' do
      expect(described_class).to_not permit(partner_admin, partner_admin_membership)
    end

    context 'with anyone else' do
      %i[partner_readonly partner_developer other_user].each do |role_name|
        it "forbids #{role_name}" do
          new_membership = team.user_teams.build
          expect(described_class).to_not permit(send(role_name), new_membership)
        end
      end
    end
  end

  permissions :destroy? do
    it 'allows login.gov admins' do
      expect(described_class).to permit(logingov_admin, partner_admin_membership)
    end

    it 'allows login.gov admins to delete their own membership' do
      admin_team_membership = create(
        :user_team,
        user: logingov_admin,
        team: partner_admin_membership.team,
      )
      expect(described_class).to permit(logingov_admin, admin_team_membership)
    end

    it 'allows Partner Admins on the same team' do
      new_membership = partner_admin_membership.team.user_teams.build
      expect(described_class).to permit(partner_admin, new_membership)
    end

    it 'forbids Partner Admins on their own membership' do
      expect(described_class).to_not permit(partner_admin, partner_admin_membership)
    end

    it 'forbids Partner Developers on the same team' do
      new_membership = partner_developer_membership.team.user_teams.build
      expect(described_class).to_not permit(partner_developer, new_membership)
    end
  end
end
