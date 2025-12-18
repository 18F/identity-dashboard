require 'rails_helper'

RSpec.describe TeamMembership do
  describe '#user_id' do
    it {
      expect(subject).to validate_uniqueness_of(:user_id).scoped_to(:group_id).
        with_message('0 is already a member of the team.')
    }
  end

  describe 'paper_trail', :versioning do
    it { is_expected.to be_versioned }

    it 'tracks creation' do
      user = create(:user)
      team = create(:team)

      expect { create(:team_membership, user:, team:) }.to \
        change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks updates' do
      team_membership = create(:team_membership)
      other_team = create(:team)

      expect { team_membership.update!(team: other_team) }.to \
        change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks deletion' do
      team_membership = create(:team_membership)

      expect { team_membership.destroy }.to change { PaperTrail::Version.count }.by(1)
    end
  end

  describe '#valid?' do
    it { is_expected.to allow_value(nil).for(:role_name) }
    it { is_expected.to allow_value('logingov_admin').for(:role_name) }
    it { is_expected.to_not allow_value('some_random_admin').for(:role_name) }
  end

  describe '.destroy_orphaned_memberships' do
    let(:logger) do
      logger = object_double(Logger.new(STDOUT))
      allow(logger).to receive(:warn)
      logger
    end

    it 'with only valid team memberships it logs nothing and deletes nothing' do
      valid_team_membership1 = create(:team_membership)
      valid_team_membership2 = create(:team_membership, [:partner_admin, :partner_readonly].sample)
      described_class.destroy_orphaned_memberships(logger:)
      valid_team_membership1.reload
      expect(valid_team_membership1).to be_valid
      valid_team_membership2.reload
      expect(valid_team_membership2).to be_valid
      expect(logger).to_not have_received(:warn)
    end

    it 'with a null user it logs deleting the membership while keeping related records' do
      valid_team_membership = create(:team_membership)
      affected_team = valid_team_membership.team
      invalidated_team_membership = create(:team_membership, team: affected_team)
      invalidated_team_membership.update_column(:user_id, nil)
      described_class.destroy_orphaned_memberships(logger:)

      expect(logger).to have_received(:warn).with(
        "Deleting team memberships #{[invalidated_team_membership.id]} missing user IDs",
      )

      expect { invalidated_team_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      affected_team.reload
      valid_team_membership.reload
      expect(valid_team_membership).to be_valid
      expect(valid_team_membership.team).to eq(affected_team)
    end

    it 'with a user ID that is not valid it deletes the team membership while keeping the team' do
      invalidated_team_membership = create(:team_membership)
      affected_team = invalidated_team_membership.team
      invalidated_team_membership.update_column(:user_id, User.last.id + rand(100..10000))
      expect do
        User.find(invalidated_team_membership.user_id)
      end.to raise_error(ActiveRecord::RecordNotFound)

      described_class.destroy_orphaned_memberships

      expect { invalidated_team_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      affected_team.reload
      expect(affected_team).to be_valid
    end

    it 'with a team ID that is not valid it deletes the membership while keeping the user' do
      invalidated_team_membership = create(:team_membership)
      affected_user = invalidated_team_membership.user
      invalidated_team_membership.update_column(:group_id, Team.last.id + rand(100..10000))
      expect do
        Team.find(invalidated_team_membership.group_id)
      end.to raise_error(ActiveRecord::RecordNotFound)

      described_class.destroy_orphaned_memberships

      expect { invalidated_team_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      affected_user.reload
      expect(affected_user).to be_valid
    end

    it 'deletes a membership with a null team while keeping related records' do
      valid_team_membership = create(:team_membership)
      affected_user = valid_team_membership.user
      invalidated_team_membership = create(:team_membership, user: affected_user)
      invalidated_team_membership.update_column(:group_id, nil)
      described_class.destroy_orphaned_memberships(logger:)

      expect(logger).to have_received(:warn).with(
        "Deleting team memberships #{[invalidated_team_membership.id]} missing team IDs",
      )
      expect { invalidated_team_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
      affected_user.reload
      valid_team_membership.reload
      expect(valid_team_membership).to be_valid
      expect(valid_team_membership.user).to eq(affected_user)
    end
  end
end
