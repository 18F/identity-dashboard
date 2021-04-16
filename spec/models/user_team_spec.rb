require 'rails_helper'

RSpec.describe UserTeam, type: :model do
  describe 'paper_trail', versioning: true do
    it { is_expected.to be_versioned }

    it 'tracks creation' do
      user = create(:user)
      team = create(:team)

      expect { create(:user_team, user: user, team: team) }.to \
        change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks updates' do
      user_team = create(:user_team)
      other_team = create(:team)

      expect { user_team.update!(team: other_team) }.to \
        change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks deletion' do
      user_team = create(:user_team)

      expect { user_team.destroy }.to change { PaperTrail::Version.count }.by(1)
    end
  end
end
