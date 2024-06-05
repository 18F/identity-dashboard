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

  describe '.paper_trail_by_team_id', versioning: true do
    it 'can find creations and deletions' do
      PaperTrail.config.version_limit = nil
      team = create(:team)
      wrong_team = create(:team)
      added_user = create(:user)
      added_and_removed_user = create(:user)
      added_and_destroyed_user = create(:user)
      wrong_user = create(:user)

      team.users << added_user

      team.users << added_and_removed_user
      team.users.delete(added_and_removed_user)

      team.users << added_and_destroyed_user
      added_and_destroyed_user.destroy!

      wrong_team.users << wrong_user

      trail = UserTeam.paper_trail_by_team_id(team.id)

      expect(trail[0].event).to eq('create')
      expect(trail[0].object_changes['user_id']).to eq([nil, added_user.id])

      expect(trail[1].event).to eq('create')
      expect(trail[1].object_changes['user_id']).to eq([nil, added_and_removed_user.id])

      expect(trail[2].event).to eq('destroy')
      expect(trail[2].object_changes['user_id']).to eq([added_and_removed_user.id, nil])

      expect(trail[3].event).to eq('create')
      expect(trail[3].object_changes['user_id']).to eq([nil, added_and_destroyed_user.id])

      expect(trail[4].event).to eq('destroy')
      expect(trail[4].object_changes['user_id']).to eq([added_and_destroyed_user.id, nil])

      expect(trail.count).to be(5)

      expect(team.users.count).to be(1)
      expect(team.users[0]).to eq(added_user)
    end
  end
end
