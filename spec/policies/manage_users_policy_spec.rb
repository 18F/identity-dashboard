require 'rails_helper'

describe ManageUsersPolicy do
  let(:admin_user) { build(:user, admin: true) }
  let(:team_user) { build(:user) }
  let(:other_user) { build(:user) }
  let(:team) { build(:team) }

  before do
    team.users << team_user
  end

  permissions :new? do
    it 'allows team member or admin to initiate' do
      expect(ManageUsersPolicy).to permit(admin_user, team)
      expect(ManageUsersPolicy).to permit(team_user, team)
      expect(ManageUsersPolicy).to_not permit(other_user, team)
    end
  end

  permissions :create? do
    it 'allows team member or admin to create' do
      expect(ManageUsersPolicy).to permit(admin_user, team)
      expect(ManageUsersPolicy).to permit(team_user, team)
      expect(ManageUsersPolicy).to_not permit(other_user, team)
    end
  end

  permissions :delete? do
    it 'allows team member or admin to delete' do
      expect(ManageUsersPolicy).to permit(admin_user, team)
      expect(ManageUsersPolicy).to permit(team_user, team)
      expect(ManageUsersPolicy).to_not permit(other_user, team)
    end
  end
end
