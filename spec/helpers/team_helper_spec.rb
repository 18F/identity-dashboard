require 'rails_helper'
describe TeamHelper do
  let(:user) { build(:user) }

  describe '#can_edit_teams?' do
    it "returns false if user doesn't have a team" do
      expect(can_edit_teams?(user)).to be_falsy
    end

    it 'returns true if user has a team' do
      user.teams = [create(:team)]
      user.save

      expect(can_edit_teams?(user)).to be_truthy
    end

    it 'returns true if user is a login.gov admin' do
      user = create(:user, :logingov_admin)

      expect(can_edit_teams?(user)).to be_truthy
    end
  end
end
