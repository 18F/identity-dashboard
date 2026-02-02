require 'rails_helper'
describe TeamHelper do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:logingov_readonly) { build(:user, :logingov_readonly) }
  let(:partner_admin) { build(:user, :partner_admin) }
  let(:partner_dev) { build(:user, :partner_developer) }
  let(:partner_readonly) { build(:user, :partner_readonly) }

  describe '#can_edit_teams?' do
    it "returns false if user doesn't have a team" do
      expect(can_edit_teams?(partner_admin)).to be_falsy
    end

    it 'returns true if user has a team' do
      partner_admin.teams = [create(:team)]

      expect(can_edit_teams?(partner_admin)).to be_truthy
    end

    it 'returns true if user is a login.gov admin' do
      expect(can_edit_teams?(logingov_admin)).to be_truthy
    end
  end

  describe '#can_delete_team?' do
    it 'returns true if user is a Login.gov Admin' do
      partner_admin.teams = [create(:team)]
      team = partner_admin.teams.first

      expect(can_delete_team?(logingov_admin, team)).to be_truthy
    end

    it 'returns true if user is a Partner Admin' do
      partner_admin.teams = [create(:team)]
      team = partner_admin.teams.first

      expect(can_delete_team?(partner_admin, team)).to be_truthy
    end

    it 'returns false for lower roles' do
      partner_admin.teams = [create(:team)]
      team = partner_admin.teams.first
      partner_dev.teams = [team]
      partner_readonly.teams = [team]

      expect(can_delete_team?(logingov_readonly, team)).to be_falsy
      expect(can_delete_team?(partner_dev, team)).to be_falsy
      expect(can_delete_team?(partner_readonly, team)).to be_falsy
    end
  end
end
