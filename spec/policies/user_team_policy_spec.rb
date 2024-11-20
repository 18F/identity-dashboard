require 'rails_helper'

describe UserTeamPolicy do
  let(:admin_user) { build(:admin) }
  let(:team_user) { build(:user) }
  let(:other_user) { build(:restricted_ic) }
  let(:team) { build(:team) }

  before do
    team.users << team_user
  end

  permissions :manage_team_users? do
    it 'allows team member to manage team users' do
      expect(UserTeamPolicy).to permit(team_user, team)
    end

    it 'allows admin to manage team users' do
      expect(UserTeamPolicy).to permit(team_user, team)
    end

    it 'does not allow a random user to manage team users' do
      expect(UserTeamPolicy).to_not permit(other_user, team)
    end
  end
end
