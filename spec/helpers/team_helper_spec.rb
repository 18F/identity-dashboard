require 'rails_helper'
describe TeamHelper do
  let(:user) { create(:restricted_ic) }
  describe '#can_edit_teams?' do
    it "returns false if user doesn't have a team" do
      expect(can_edit_teams?(user)).to eq(false)
    end

    it 'returns true if user has a team' do
      user.teams = [create(:team)]
      user.save

      expect(can_edit_teams?(user)).to eq(true)
    end

    context 'user is an admin' do
      let(:user) { create(:admin) }
      it 'returns true if user is an admin' do
        expect(can_edit_teams?(user)).to eq(true)
      end
    end
  end
end
