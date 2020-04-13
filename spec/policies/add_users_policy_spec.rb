require 'rails_helper'

describe AddUsersPolicy do
  let(:admin_user) { build(:user, admin: true) }
  let(:team_user) { build(:user) }
  let(:other_user) { build(:user) }
  let(:team) { build(:team) }

  before do
    team.users << team_user
  end

  permissions :new? do
    it 'allows team member or admin to initiate' do
      expect(AddUsersPolicy).to permit(admin_user, team)
      expect(AddUsersPolicy).to permit(team_user, team)
      expect(AddUsersPolicy).to_not permit(other_user, team)
    end
  end

  permissions :create? do
    it 'allows team member or admin to create' do
      expect(AddUsersPolicy).to permit(admin_user, team)
      expect(AddUsersPolicy).to permit(team_user, team)
      expect(AddUsersPolicy).to_not permit(other_user, team)
    end
  end
end
