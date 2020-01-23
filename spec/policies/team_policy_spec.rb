require 'rails_helper'

describe TeamPolicy do
  let(:admin_user) { build(:user, admin: true) }
  let(:team_user) { build(:user) }
  let(:other_user) { build(:user) }
  let(:team)      { build(:team) }

  before do
    team.users << team_user
  end

  permissions :create? do
    it 'allows admin users to create' do
      expect(TeamPolicy).to permit(admin_user, team)
    end
  end

  permissions :edit? do
    it 'allows team member or admin to edit' do
      expect(TeamPolicy).to permit(admin_user, team)
      expect(TeamPolicy).to permit(team_user, team)
      expect(TeamPolicy).to_not permit(other_user, team)
    end
  end

  permissions :update? do
    it 'allows team member or admin to update' do
      expect(TeamPolicy).to permit(admin_user, team)
      expect(TeamPolicy).to permit(team_user, team)
      expect(TeamPolicy).to_not permit(other_user, team)
    end
  end

  permissions :new? do
    it 'allows admin user to initiate' do
      expect(TeamPolicy).to permit(admin_user, team)
      expect(TeamPolicy).to_not permit(team_user, team)
      expect(TeamPolicy).to_not permit(other_user, team)
    end
  end

  permissions :destroy? do
    it 'allows admin to destroy' do
      expect(TeamPolicy).to permit(admin_user, team)
      expect(TeamPolicy).to_not permit(team_user, team)
      expect(TeamPolicy).to_not permit(other_user, team)
    end
  end

  permissions :show? do
    it 'allows team member or admin to show' do
      expect(TeamPolicy).to permit(admin_user, team)
      expect(TeamPolicy).to permit(team_user, team)
      expect(TeamPolicy).to_not permit(other_user, team)
    end
  end
end
