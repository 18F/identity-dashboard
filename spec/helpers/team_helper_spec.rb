require 'rails_helper'
describe TeamHelper do
  let(:user) { build(:user) }
  let!(:current_user) { user }

  describe '#can_edit_teams?' do
    it "returns false if user doesn't have a team" do
      expect(can_edit_teams?(user)).to eq(false)
    end

    it 'returns true if user has a team' do
      user.teams = [create(:team)]
      user.save

      expect(can_edit_teams?(user)).to eq(true)
    end

    it 'returns true if user is an admin' do
      user.admin = true
      user.save

      expect(can_edit_teams?(user)).to eq(true)
    end
  end

  describe '#allowed_email?' do
    it 'allows expected emails' do
      expect(allowed_email?).to be false
    end
  end
end
