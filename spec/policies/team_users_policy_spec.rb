require 'rails_helper'

describe TeamUsersPolicy do
  let(:admin_user) { build(:user, admin: true) }
  let(:team_user) { build(:user) }
  let(:other_user) { build(:user) }
  let(:team) { build(:team) }

  before do
    team.users << team_user
  end

  permissions :new? do
    it 'allows team member or admin to initiate' do
      expect(TeamUsersPolicy).to permit(admin_user, team)
      expect(TeamUsersPolicy).to permit(team_user, team)
      expect(TeamUsersPolicy).to_not permit(other_user, team)
    end
  end

  permissions :create? do
    it 'allows team member or admin to create' do
      expect(TeamUsersPolicy).to permit(admin_user, team)
      expect(TeamUsersPolicy).to permit(team_user, team)
      expect(TeamUsersPolicy).to_not permit(other_user, team)
    end
  end

  permissions :remove_confirm? do
    it 'allows team member or admin to view delete page' do
      expect(TeamUsersPolicy).to permit(admin_user, team)
      expect(TeamUsersPolicy).to permit(team_user, team)
      expect(TeamUsersPolicy).to_not permit(other_user, team)
    end
  end

  permissions :destroy? do
    it 'allows team member or admin to view delete page' do
      expect(TeamUsersPolicy).to permit(admin_user, team)
      expect(TeamUsersPolicy).to permit(team_user, team)
      expect(TeamUsersPolicy).to_not permit(other_user, team)
    end
  end
end
