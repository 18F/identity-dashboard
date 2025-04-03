require 'rails_helper'

RSpec.describe UserTeam, type: :model do
  describe '#user_id' do
    it {
      is_expected.to validate_uniqueness_of(:user_id).scoped_to(:group_id).
        with_message('This user is already a member of the team.')
    }
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
    it { is_expected.to allow_value('logingov_admin').for(:role_name) }
    it { is_expected.not_to allow_value('some_random_admin').for(:role_name) }
  end

  describe '.destroy_orphaned_memberships' do
    let(:logger) do
      logger = object_double(Logger.new(STDOUT))
      allow(logger).to receive(:warn)
      logger
    end

    it 'with only valid memberships it logs nothing and deletes nothing' do
      valid_membership1 = create(:user_team)
      valid_membership2 = create(:user_team, [:partner_admin, :partner_readonly].sample)
      UserTeam.destroy_orphaned_memberships(logger:)
      valid_membership1.reload
      expect(valid_membership1).to be_valid
      valid_membership2.reload
      expect(valid_membership2).to be_valid
      expect(logger).to_not have_received(:warn)
    end

    it 'with a null user it logs deleting the membership while keeping related records' do
      valid_membership = create(:user_team)
      affected_team = valid_membership.team
      invalidated_membership = create(:user_team, team: affected_team)
      invalidated_membership.update_column(:user_id, nil)
      UserTeam.destroy_orphaned_memberships(logger:)

      expect(logger).to have_received(:warn).with(
        "Deleting team memberships #{[invalidated_membership.id]} missing user IDs",
      )

      expect { invalidated_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      affected_team.reload
      valid_membership.reload
      expect(valid_membership).to be_valid
      expect(valid_membership.team).to eq(affected_team)
    end

    it 'with a user ID that is not valid it deletes the membership while keeping the team' do
      invalidated_membership = create(:user_team)
      affected_team = invalidated_membership.team
      invalidated_membership.update_column(:user_id, User.last.id + rand(100.10000))
      expect do
        User.find(invalidated_membership.user_id)
      end.to raise_error(ActiveRecord::RecordNotFound)

      UserTeam.destroy_orphaned_memberships

      expect { invalidated_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      affected_team.reload
      expect(affected_team).to be_valid
    end

    it 'with a team ID that is not valid it deletes the membership while keeping the user' do
      invalidated_membership = create(:user_team)
      affected_user = invalidated_membership.user
      invalidated_membership.update_column(:group_id, Team.last.id + rand(100.10000))
      expect do
        Team.find(invalidated_membership.group_id)
      end.to raise_error(ActiveRecord::RecordNotFound)

      UserTeam.destroy_orphaned_memberships

      expect { invalidated_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      affected_user.reload
      expect(affected_user).to be_valid
    end

    it 'deletes a membership with a null team while keeping related records' do
      valid_membership = create(:user_team)
      affected_user = valid_membership.user
      invalidated_membership = create(:user_team, user: affected_user)
      invalidated_membership.update_column(:group_id, nil)
      UserTeam.destroy_orphaned_memberships(logger:)

      expect(logger).to have_received(:warn).with(
        "Deleting team memberships #{[invalidated_membership.id]} missing team IDs",
      )
      expect { invalidated_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      affected_user.reload
      valid_membership.reload
      expect(valid_membership).to be_valid
      expect(valid_membership.user).to eq(affected_user)
    end
  end
end
