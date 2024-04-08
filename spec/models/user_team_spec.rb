require 'rails_helper'

RSpec.describe UserTeam, type: :model do
  describe '#user_id' do
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:group_id). \
    with_message('This user is already a member of the team.') }
  end

  describe 'paper_trail', versioning: true do
    it { is_expected.to be_versioned }

    it 'tracks creation' do
      user = create(:restricted_ic)
      team = create(:team)

      expect { create(:restricted_ic_team, user: user, team: team) }.to \
        change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks updates' do
      user_team = create(:restricted_ic_team)
      other_team = create(:team)

      expect { user_team.update!(team: other_team) }.to \
        change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks deletion' do
      user_team = create(:restricted_ic_team)

      expect { user_team.destroy }.to change { PaperTrail::Version.count }.by(1)
    end
  end
end
