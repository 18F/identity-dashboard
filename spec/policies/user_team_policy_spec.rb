require 'rails_helper'

describe UserTeamPolicy do
  let(:partner_admin_access) { create(:user_team, :partner_admin)}
  let(:partner_developer_access) { create(:user_team, :partner_developer) }
  let(:partner_readonly_access) { create(:user_team, :partner_readonly) }
  let(:partner_admin) { partner_admin_access.user }
  let(:partner_developer) { partner_developer_access.user }
  let(:partner_readonly ) { partner_readonly_access.user }
  let(:site_admin) { build(:admin) }
  let(:other_user) { build(:restricted_ic) }
  let(:without_role_access) { create(:user_team)}

  permissions :manage_team_users? do
    before do
      expect(IdentityConfig.store).to receive(:access_controls_enabled).at_most(1).and_return(false)
    end

    it 'allows team member to manage team users' do
      expect(UserTeamPolicy).to permit(without_role_access.user, without_role_access)
    end

    it 'allows admin to manage team users' do
      expect(UserTeamPolicy).to permit(site_admin, without_role_access)
    end

    it 'does not allow a random user to manage team users' do
      expect(UserTeamPolicy).to_not permit(other_user, without_role_access)
    end
  end

  permissions :index? do
    it 'allows Partner Admins' do
      expect(UserTeamPolicy).to permit(partner_admin, partner_admin_access)
    end

    it 'allows Partner Developers' do
      expect(UserTeamPolicy).to permit(partner_developer, partner_developer_access)
    end

    it 'forbids Partner Readonly' do
      expect(UserTeamPolicy).to_not permit(partner_readonly, partner_readonly_access)
    end
  end

  permissions :create? do
    it 'allows Partner Admins' do
      new_access = partner_admin_access.team.user_teams.build
      expect(UserTeamPolicy).to permit(partner_admin, new_access)
    end

    it 'forbids Partner Developers' do
      new_access = partner_developer_access.team.user_teams.build
      expect(UserTeamPolicy).to_not permit(partner_developer, new_access)
    end

    it 'forbids Partner Readonly' do
      new_access = partner_readonly_access.team.user_teams.build
      expect(UserTeamPolicy).to_not permit(partner_readonly, new_access)
    end
  end

  permissions :destroy? do
    it 'allows site admins' do
      expect(UserTeamPolicy).to permit(site_admin, partner_admin_access)
    end

    it 'allows site admins to delete their own access' do
      admin_team_access = create(:user_team, user: site_admin, team: partner_admin_access.team)
      expect(UserTeamPolicy).to permit(site_admin, admin_team_access)
    end

    it 'allows Partner Admins on the same team' do
      new_access = partner_admin_access.team.user_teams.build
      expect(UserTeamPolicy).to permit(partner_admin, new_access)
    end

    it 'forbids Partner Admins on their own access' do
      expect(UserTeamPolicy).to_not permit(partner_admin, partner_admin_access)
    end

    it 'forbids Partner Developers on the same team' do
      new_access = partner_developer_access.team.user_teams.build
      expect(UserTeamPolicy).to_not permit(partner_developer, new_access)
    end
  end
end
