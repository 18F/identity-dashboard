require 'rails_helper'

RSpec.describe UserTeam, type: :model do
  describe '#user_id' do
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:group_id). \
    with_message('This user is already a member of the team.') }
  end

  describe 'paper_trail', versioning: true do
    it { is_expected.to be_versioned }

    it 'tracks creation' do
      user = create(:user)
      team = create(:team)

      expect { create(:user_team, user:, team:) }.to \
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

  describe '#valid?' do
    it { is_expected.to allow_value(nil).for(:role_name) }
    it { is_expected.to allow_value('Login.gov Admin').for(:role_name) }
    it { is_expected.to_not allow_value('Some Random Admin').for(:role_name) }
  end
end
